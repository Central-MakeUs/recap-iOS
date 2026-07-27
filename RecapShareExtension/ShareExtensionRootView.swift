import Observation
import PhotosUI
import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct ShareExtensionRootView: View {
    @State private var viewModel: ShareExtensionViewModel
    @State private var isPhotoPickerPresented = false
    @State private var isCancellationDialogPresented = false
    @State private var pickerItems: [PhotosPickerItem] = []

    init(extensionContext: NSExtensionContext?) {
        _viewModel = State(
            initialValue: ShareExtensionViewModel(extensionContext: extensionContext)
        )
    }

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("공유한 이미지를 불러오는 중이에요")
                    .font(.custom("Pretendard-Medium", size: 14))
            } else {
                SelectedScreenshotsConfirmationView(
                    screenshots: viewModel.screenshots,
                    isSubmitting: viewModel.isSubmitting,
                    message: viewModel.message,
                    toastMessage: viewModel.toastMessage,
                    onBack: presentCancellationDialog,
                    onAdd: { isPhotoPickerPresented = true },
                    onRemove: viewModel.removeScreenshot,
                    onConfirm: submit
                )
            }
        }
        .task {
            await viewModel.loadSharedImages()
        }
        .photosPicker(
            isPresented: $isPhotoPickerPresented,
            selection: $pickerItems,
            maxSelectionCount: max(1, 20 - viewModel.screenshots.count),
            matching: .screenshots
        )
        .onChange(of: pickerItems) { _, items in
            guard !items.isEmpty else { return }
            Task {
                await viewModel.appendPickerItems(items)
                pickerItems = []
            }
        }
        .overlay {
            if isCancellationDialogPresented {
                ZStack {
                    Color.black.opacity(0.30)
                        .ignoresSafeArea()

                    ShareUploadCancellationDialog(
                        onContinue: dismissCancellationDialog,
                        onExit: viewModel.cancel
                    )
                }
            }
        }
    }

    private func presentCancellationDialog() {
        isCancellationDialogPresented = true
    }

    private func dismissCancellationDialog() {
        isCancellationDialogPresented = false
    }

    private func submit() {
        Task {
            await viewModel.submit()
        }
    }
}

@MainActor
@Observable
final class ShareExtensionViewModel {
    private(set) var screenshots: [SelectedScreenshot] = []
    private(set) var isLoading = true
    private(set) var isSubmitting = false
    private(set) var message: String?
    private(set) var toastMessage: String?

    private weak var extensionContext: NSExtensionContext?
    private let pipeline: ShareExtensionUploadPipeline
    private var didLoad = false

    init(
        extensionContext: NSExtensionContext?,
        pipeline: ShareExtensionUploadPipeline = ShareExtensionUploadPipeline.live()
    ) {
        self.extensionContext = extensionContext
        self.pipeline = pipeline
    }

    func loadSharedImages() async {
        guard !didLoad else { return }
        didLoad = true

        let attachments = extensionContext?.inputItems
            .compactMap { $0 as? NSExtensionItem }
            .flatMap { $0.attachments ?? [] } ?? []
        let imageProviders = attachments.filter {
            $0.hasItemConformingToTypeIdentifier(UTType.image.identifier)
        }
        let providers = Array(imageProviders.prefix(20))

        if imageProviders.count < attachments.count {
            toastMessage = "이미지가 아닌 파일은 제외했어요"
        }

        var loadedScreenshots: [SelectedScreenshot] = []
        for provider in providers {
            if let sourceData = try? await provider.imageData(),
               let imageData = sourceData.normalizedJPEGData() {
                loadedScreenshots.append(SelectedScreenshot(imageData: imageData))
            }
        }

        screenshots = loadedScreenshots
        isLoading = false
        if screenshots.isEmpty {
            message = "공유한 이미지를 불러오지 못했어요."
        }
    }

    func appendPickerItems(_ items: [PhotosPickerItem]) async {
        let availableCount = max(0, 20 - screenshots.count)
        guard availableCount > 0 else { return }

        for item in items.prefix(availableCount) {
            if let sourceData = try? await item.loadTransferable(type: Data.self),
               let imageData = sourceData.normalizedJPEGData() {
                screenshots.append(SelectedScreenshot(imageData: imageData))
            }
        }
    }

    func removeScreenshot(id: SelectedScreenshot.ID) {
        screenshots.removeAll { $0.id == id }
    }

    func submit() async {
        guard !screenshots.isEmpty, !isSubmitting else { return }
        isSubmitting = true
        message = nil

        do {
            try await pipeline.startOrganizing(images: screenshots.map(\.imageData))
            extensionContext?.completeRequest(returningItems: nil)
        } catch ShareExtensionUploadError.missingSession {
            message = "Recap 앱에서 로그인한 후 다시 시도해주세요."
            isSubmitting = false
        } catch ShareExtensionUploadError.uploadFailed {
            message = "이미지 업로드에 실패했어요. 다시 시도해주세요."
            isSubmitting = false
        } catch ShareExtensionUploadError.httpStatus(let statusCode) {
            message = "서버 요청에 실패했어요. (\(statusCode))"
            isSubmitting = false
        } catch ShareExtensionUploadError.keychain {
            message = "로그인 정보를 불러오지 못했어요. Recap 앱을 다시 열어주세요."
            isSubmitting = false
        } catch {
            message = "스크린샷 정리를 시작하지 못했어요. 다시 시도해주세요."
            isSubmitting = false
        }
    }

    func cancel() {
        extensionContext?.cancelRequest(
            withError: CocoaError(.userCancelled)
        )
    }
}

private extension Data {
    func normalizedJPEGData() -> Data? {
        UIImage(data: self)?.jpegData(compressionQuality: 0.9)
    }
}

private extension NSItemProvider {
    func imageData() async throws -> Data {
        try await withCheckedThrowingContinuation { continuation in
            loadDataRepresentation(forTypeIdentifier: UTType.image.identifier) { data, error in
                if let data {
                    continuation.resume(returning: data)
                } else {
                    continuation.resume(
                        throwing: error ?? CocoaError(.fileReadUnknown)
                    )
                }
            }
        }
    }
}
