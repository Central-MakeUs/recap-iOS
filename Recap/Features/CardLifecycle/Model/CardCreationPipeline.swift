import Foundation

struct CardCreationProgress: Equatable, Sendable {
    enum Phase: Equatable, Sendable {
        case preparing
        case uploading
        case organizing
        case completed
    }

    let phase: Phase
    let fractionCompleted: Double

    nonisolated init(phase: Phase, fractionCompleted: Double) {
        self.phase = phase
        self.fractionCompleted = min(max(fractionCompleted, 0), 1)
    }

    nonisolated static let initial = CardCreationProgress(
        phase: .preparing,
        fractionCompleted: 0
    )
}

protocol CardCreationProcessing: Sendable {
    func process(
        images: [Data],
        progress: @escaping @MainActor @Sendable (CardCreationProgress) -> Void
    ) async throws -> OrganizeStatusResponseDTO
    func cancelCurrentProcess() async
}

extension CardCreationProcessing {
    func process(images: [Data]) async throws -> OrganizeStatusResponseDTO {
        try await process(images: images, progress: { _ in })
    }
}

actor CardCreationPipeline: CardCreationProcessing {
    private let captureService: any CaptureServing
    private let imageUploader: any PresignedImageUploading
    private let pollingInterval: Duration
    private let maximumPollingAttempts: Int

    private var currentBatchID: Int64?

    init(
        captureService: any CaptureServing,
        imageUploader: any PresignedImageUploading,
        pollingInterval: Duration = .seconds(1),
        maximumPollingAttempts: Int = 120
    ) {
        self.captureService = captureService
        self.imageUploader = imageUploader
        self.pollingInterval = pollingInterval
        self.maximumPollingAttempts = maximumPollingAttempts
    }

    func process(
        images: [Data],
        progress: @escaping @MainActor @Sendable (CardCreationProgress) -> Void
    ) async throws -> OrganizeStatusResponseDTO {
        guard (1...20).contains(images.count) else {
            throw CaptureLifecycleError.invalidImageCount
        }

        await progress(.init(phase: .preparing, fractionCompleted: 0.05))
        let uploadItems = try await captureService.issueUploadURLs(count: images.count)
        guard uploadItems.count == images.count else {
            throw CaptureLifecycleError.uploadCountMismatch
        }

        await progress(.init(phase: .uploading, fractionCompleted: 0.12))
        try await upload(
            images: images,
            items: uploadItems,
            progress: progress
        )
        try Task.checkCancellation()

        await progress(.init(phase: .organizing, fractionCompleted: 0.65))
        let organize = try await captureService.organize(
            imageKeys: uploadItems.map(\.imageKey)
        )
        currentBatchID = organize.batchId
        defer { currentBatchID = nil }

        if organize.status.isTerminal {
            let status = OrganizeStatusResponseDTO(
                batchId: organize.batchId,
                status: organize.status,
                totalCount: organize.totalCount,
                successCount: organize.status == .completed ? organize.totalCount : 0,
                failCount: organize.status == .failed ? organize.totalCount : 0
            )
            await progress(.init(phase: .completed, fractionCompleted: 1))
            await acknowledgeIfNeeded(status)
            return status
        }

        for attempt in 0..<maximumPollingAttempts {
            try Task.checkCancellation()
            try await Task.sleep(for: pollingInterval)
            let status = try await captureService.organizeStatus(batchID: organize.batchId)
            if status.status.isTerminal {
                await progress(.init(phase: .completed, fractionCompleted: 1))
                await acknowledgeIfNeeded(status)
                return status
            }

            let pollingFraction = Double(attempt + 1) / Double(maximumPollingAttempts)
            await progress(
                .init(
                    phase: .organizing,
                    fractionCompleted: 0.7 + (0.25 * pollingFraction)
                )
            )
        }

        throw CaptureLifecycleError.pollingTimedOut
    }

    func cancelCurrentProcess() async {
        guard let currentBatchID else { return }
        try? await captureService.cancelOrganize(batchID: currentBatchID)
        self.currentBatchID = nil
    }

    private func upload(
        images: [Data],
        items: [UploadItemDTO],
        progress: @escaping @MainActor @Sendable (CardCreationProgress) -> Void
    ) async throws {
        let imageUploader = imageUploader

        try await withThrowingTaskGroup(of: Void.self) { group in
            for (image, item) in zip(images, items) {
                group.addTask {
                    try await imageUploader.upload(image, to: item.uploadUrl)
                }
            }

            var completedUploadCount = 0
            for try await _ in group {
                completedUploadCount += 1
                let uploadFraction = Double(completedUploadCount) / Double(items.count)
                await progress(
                    .init(
                        phase: .uploading,
                        fractionCompleted: 0.12 + (0.43 * uploadFraction)
                    )
                )
            }
        }
    }

    private func acknowledgeIfNeeded(_ result: OrganizeStatusResponseDTO) async {
        switch result.status {
        case .completed, .partialFailed, .failed:
            try? await captureService.acknowledgeOrganizeResult(batchID: result.batchId)
        case .processing, .cancelled:
            break
        }
    }
}
