import Observation
import PhotosUI
import SwiftUI
import UniformTypeIdentifiers

struct ShareExtensionRootView: View {
    @State private var viewModel: ShareExtensionViewModel
    @State private var isPhotoPickerPresented = false
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
                    onBack: viewModel.cancel,
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

        let providers = Array((extensionContext?.inputItems
            .compactMap { $0 as? NSExtensionItem }
            .flatMap { $0.attachments ?? [] }
            .filter { $0.hasItemConformingToTypeIdentifier(UTType.image.identifier) }
            .prefix(20)) ?? [])

        var loadedScreenshots: [SelectedScreenshot] = []
        for provider in providers {
            if let data = try? await provider.imageData() {
                loadedScreenshots.append(SelectedScreenshot(imageData: data))
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
            if let data = try? await item.loadTransferable(type: Data.self) {
                screenshots.append(SelectedScreenshot(imageData: data))
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
