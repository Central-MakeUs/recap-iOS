import Foundation

protocol CardCreationProcessing: Sendable {
    func process(images: [Data]) async throws -> OrganizeStatusResponseDTO
    func cancelCurrentProcess() async
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

    func process(images: [Data]) async throws -> OrganizeStatusResponseDTO {
        guard (1...20).contains(images.count) else {
            throw CaptureLifecycleError.invalidImageCount
        }

        let uploadItems = try await captureService.issueUploadURLs(count: images.count)
        guard uploadItems.count == images.count else {
            throw CaptureLifecycleError.uploadCountMismatch
        }

        try await upload(images: images, items: uploadItems)
        try Task.checkCancellation()

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
            await acknowledgeIfNeeded(status)
            return status
        }

        for _ in 0..<maximumPollingAttempts {
            try Task.checkCancellation()
            try await Task.sleep(for: pollingInterval)
            let status = try await captureService.organizeStatus(batchID: organize.batchId)
            if status.status.isTerminal {
                await acknowledgeIfNeeded(status)
                return status
            }
        }

        throw CaptureLifecycleError.pollingTimedOut
    }

    func cancelCurrentProcess() async {
        guard let currentBatchID else { return }
        try? await captureService.cancelOrganize(batchID: currentBatchID)
        self.currentBatchID = nil
    }

    private func upload(images: [Data], items: [UploadItemDTO]) async throws {
        let imageUploader = imageUploader

        try await withThrowingTaskGroup(of: Void.self) { group in
            for (image, item) in zip(images, items) {
                group.addTask {
                    try await imageUploader.upload(image, to: item.uploadUrl)
                }
            }

            try await group.waitForAll()
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
