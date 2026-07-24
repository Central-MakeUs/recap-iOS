import Foundation

nonisolated struct UploadURLsRequestDTO: Encodable, Sendable {
    let count: Int
}

nonisolated struct UploadURLsResponseDTO: Decodable, Sendable {
    let uploads: [UploadItemDTO]
}

nonisolated struct UploadItemDTO: Decodable, Sendable {
    let imageKey: String
    let uploadUrl: URL
}

nonisolated struct OrganizeRequestDTO: Encodable, Sendable {
    let imageKeys: [String]
}

nonisolated struct OrganizeResponseDTO: Decodable, Sendable {
    let batchId: Int64
    let totalCount: Int
    let status: OrganizeStatus
}

nonisolated struct OrganizeStatusResponseDTO: Decodable, Sendable {
    let batchId: Int64
    let status: OrganizeStatus
    let totalCount: Int
    let successCount: Int
    let failCount: Int
}

nonisolated struct PendingOrganizeResultDTO: Decodable, Sendable {
    let batchId: Int64
    let status: OrganizeStatus
    let successCount: Int
    let failCount: Int
}

nonisolated enum OrganizeStatus: String, Decodable, Sendable {
    case processing = "PROCESSING"
    case completed = "COMPLETED"
    case partialFailed = "PARTIAL_FAILED"
    case failed = "FAILED"
    case cancelled = "CANCELLED"

    var isTerminal: Bool {
        self != .processing
    }
}

nonisolated struct CaptureDetailDTO: Decodable, Sendable {
    let captureId: Int64
    let typeCode: CardTypeCode
    let title: String
    let summary: String
    let body: String
    let originalImageUrl: URL
    let isFavorite: Bool
    let organizedAt: Date
}

nonisolated struct FavoriteRequestDTO: Encodable, Sendable {
    let isFavorite: Bool
}
