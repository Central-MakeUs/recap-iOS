import Foundation

final class PreviewCaptureService: CaptureServing, @unchecked Sendable {
    func issueUploadURLs(count: Int) async throws -> [UploadItemDTO] {
        (0..<count).map { index in
            UploadItemDTO(
                imageKey: "preview/\(index).jpg",
                uploadUrl: URL(string: "https://preview.invalid/\(index)")!
            )
        }
    }

    func organize(imageKeys: [String]) async throws -> OrganizeResponseDTO {
        OrganizeResponseDTO(
            batchId: 1,
            totalCount: imageKeys.count,
            status: .completed
        )
    }

    func organizeStatus(batchID: Int64) async throws -> OrganizeStatusResponseDTO {
        OrganizeStatusResponseDTO(
            batchId: batchID,
            status: .completed,
            totalCount: 1,
            successCount: 1,
            failCount: 0
        )
    }

    func cancelOrganize(batchID: Int64) async throws {}
    func pendingOrganizeResult() async throws -> PendingOrganizeResultDTO? { nil }
    func acknowledgeOrganizeResult(batchID: Int64) async throws {}
    func captureDetail(captureID: Int64) async throws -> InformationCard {
        SampleData.cards.first { $0.captureID == captureID } ?? SampleData.cards[0]
    }
    func updateFavorite(captureID: Int64, isFavorite: Bool) async throws {}
    func deleteCapture(captureID: Int64) async throws {}
}

actor PreviewCardCreationPipeline: CardCreationProcessing {
    func process(images: [Data]) async throws -> OrganizeStatusResponseDTO {
        try await Task.sleep(for: .seconds(1.2))
        return OrganizeStatusResponseDTO(
            batchId: 1,
            status: .completed,
            totalCount: images.count,
            successCount: images.count,
            failCount: 0
        )
    }

    func cancelCurrentProcess() async {}
}
