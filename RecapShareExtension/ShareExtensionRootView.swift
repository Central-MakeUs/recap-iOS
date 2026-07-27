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
            switch viewModel.phase {
            case .loading:
                ProgressView("공유한 이미지를 불러오는 중이에요")
                    .font(.custom("Pretendard-Medium", size: 14))
            case .confirmation:
                confirmationView
            case .organizing(let progress):
                ShareOrganizingView(
                    progress: progress,
                    onCancel: cancelOrganizing
                )
            case .complete(let organizedCount, _):
                ShareOrganizeCompleteView(
                    organizedCount: organizedCount,
                    onDone: finish
                )
            case .failure:
                ShareOrganizeFailureView(onClose: close)
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

    private var confirmationView: some View {
        SelectedScreenshotsConfirmationView(
            screenshots: viewModel.screenshots,
            isSubmitting: false,
            message: viewModel.message,
            toastMessage: viewModel.toastMessage,
            onBack: presentCancellationDialog,
            onAdd: { isPhotoPickerPresented = true },
            onRemove: viewModel.removeScreenshot,
            onConfirm: viewModel.submit
        )
    }

    private func presentCancellationDialog() {
        isCancellationDialogPresented = true
    }

    private func dismissCancellationDialog() {
        isCancellationDialogPresented = false
    }

    private func cancelOrganizing() {
        Task {
            await viewModel.cancelOrganizing()
        }
    }

    private func finish() {
        Task {
            await viewModel.finish()
        }
    }

    private func close() {
        Task {
            await viewModel.close()
        }
    }
}

enum ShareExtensionPhase: Equatable {
    case loading
    case confirmation
    case organizing(progress: Double)
    case complete(organizedCount: Int, batchID: Int64)
    case failure(batchID: Int64?)
}

@MainActor
@Observable
final class ShareExtensionViewModel {
    private(set) var screenshots: [SelectedScreenshot] = []
    private(set) var phase: ShareExtensionPhase = .loading
    private(set) var message: String?
    private(set) var toastMessage: String?

    private weak var extensionContext: NSExtensionContext?
    private let pipeline: ShareExtensionUploadPipeline
    private var didLoad = false
    @ObservationIgnored private var organizingTask: Task<Void, Never>?

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
        phase = .confirmation
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

    func submit() {
        guard !screenshots.isEmpty, phase == .confirmation else { return }
        let images = screenshots.map(\.imageData)
        message = nil
        phase = .organizing(progress: 0.05)

        organizingTask = Task { [weak self] in
            await self?.organize(images: images)
        }
    }

    func cancelOrganizing() async {
        organizingTask?.cancel()
        organizingTask = nil
        await pipeline.cancelCurrentProcess()
        extensionContext?.cancelRequest(withError: CocoaError(.userCancelled))
    }

    func finish() async {
        guard case .complete(_, let batchID) = phase else { return }
        await pipeline.acknowledge(batchID: batchID)
        extensionContext?.completeRequest(returningItems: nil)
    }

    func close() async {
        if case .failure(let batchID) = phase, let batchID {
            await pipeline.acknowledge(batchID: batchID)
        }
        extensionContext?.completeRequest(returningItems: nil)
    }

    private func organize(images: [Data]) async {
        do {
            let result = try await pipeline.organize(
                images: images,
                progress: { [weak self] progress in
                    self?.phase = .organizing(progress: progress)
                }
            )
            guard !Task.isCancelled else { return }

            switch result.status {
            case .completed:
                phase = .complete(
                    organizedCount: result.successCount,
                    batchID: result.batchID
                )
            case .partialFailed where result.successCount > 0:
                phase = .complete(
                    organizedCount: result.successCount,
                    batchID: result.batchID
                )
            case .processing, .partialFailed, .failed, .cancelled:
                phase = .failure(batchID: result.batchID)
            }
        } catch is CancellationError {
            return
        } catch ShareExtensionUploadError.missingSession {
            phase = .confirmation
            message = "Recap 앱에서 로그인한 후 다시 시도해주세요."
        } catch {
            phase = .failure(batchID: nil)
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
