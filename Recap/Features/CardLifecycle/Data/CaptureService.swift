import Foundation

protocol CaptureDeleting: Sendable {
    func deleteCapture(captureID: Int64) async throws
    func deleteCaptures(captureIDs: [Int64]) async throws
}

protocol CaptureFavoriteUpdating: Sendable {
    func updateFavorite(captureID: Int64, isFavorite: Bool) async throws
}

protocol CaptureUpdating: Sendable {
    func updateCapture(captureID: Int64, draft: CardEditDraft) async throws
}

protocol CaptureReporting: Sendable {
    func reportCapture(
        captureID: Int64,
        reason: CaptureReportReason,
        detail: String?
    ) async throws
}

protocol CaptureDetailLoading: Sendable {
    func captureDetail(captureID: Int64) async throws -> CardSnapshot
}

protocol CaptureMutating: CaptureDeleting, CaptureFavoriteUpdating, CaptureUpdating, CaptureReporting {}

protocol CaptureServing: CaptureMutating, CaptureDetailLoading, Sendable {
    func issueUploadURLs(count: Int) async throws -> [UploadItemDTO]
    func organize(imageKeys: [String]) async throws -> OrganizeResponseDTO
    func organizeStatus(batchID: Int64) async throws -> OrganizeStatusResponseDTO
    func cancelOrganize(batchID: Int64) async throws
    func pendingOrganizeResult() async throws -> PendingOrganizeResultDTO?
    func acknowledgeOrganizeResult(batchID: Int64) async throws
}

final class CaptureService: CaptureServing {
    private let networkClient: any NetworkClient
    private let encoder: JSONEncoder

    init(
        networkClient: any NetworkClient,
        encoder: JSONEncoder = JSONEncoder()
    ) {
        self.networkClient = networkClient
        self.encoder = encoder
    }

    func issueUploadURLs(count: Int) async throws -> [UploadItemDTO] {
        guard (1...20).contains(count) else {
            throw CaptureLifecycleError.invalidImageCount
        }

        let endpoint = try jsonEndpoint(
            method: .post,
            path: "/api/v1/captures/upload-urls",
            payload: UploadURLsRequestDTO(count: count)
        )
        let response: APIResponse<UploadURLsResponseDTO> = try await networkClient.send(endpoint)
        return try response.requiredData().uploads
    }

    func organize(imageKeys: [String]) async throws -> OrganizeResponseDTO {
        guard !imageKeys.isEmpty else {
            throw CaptureLifecycleError.invalidImageCount
        }

        let endpoint = try jsonEndpoint(
            method: .post,
            path: "/api/v1/captures/organize",
            payload: OrganizeRequestDTO(imageKeys: imageKeys)
        )
        let response: APIResponse<OrganizeResponseDTO> = try await networkClient.send(endpoint)
        return try response.requiredData()
    }

    func organizeStatus(batchID: Int64) async throws -> OrganizeStatusResponseDTO {
        let endpoint = APIEndpoint(
            method: .get,
            path: "/api/v1/captures/organize/\(batchID)/status",
            headers: ["Accept": "application/json"],
            authorization: .bearer
        )
        let response: APIResponse<OrganizeStatusResponseDTO> = try await networkClient.send(endpoint)
        return try response.requiredData()
    }

    func cancelOrganize(batchID: Int64) async throws {
        let endpoint = APIEndpoint(
            method: .post,
            path: "/api/v1/captures/organize/\(batchID)/cancel",
            authorization: .bearer
        )
        let _: EmptyResponse = try await networkClient.send(endpoint)
    }

    func pendingOrganizeResult() async throws -> PendingOrganizeResultDTO? {
        let endpoint = APIEndpoint(
            method: .get,
            path: "/api/v1/captures/organize/pending-result",
            headers: ["Accept": "application/json"],
            authorization: .bearer
        )
        let response: APIResponse<PendingOrganizeResultDTO> = try await networkClient.send(endpoint)
        return response.data
    }

    func acknowledgeOrganizeResult(batchID: Int64) async throws {
        let endpoint = APIEndpoint(
            method: .post,
            path: "/api/v1/captures/organize/\(batchID)/ack",
            authorization: .bearer
        )
        let _: EmptyResponse = try await networkClient.send(endpoint)
    }

    func captureDetail(captureID: Int64) async throws -> CardSnapshot {
        let endpoint = APIEndpoint(
            method: .get,
            path: "/api/v1/captures/\(captureID)",
            headers: ["Accept": "application/json"],
            authorization: .bearer
        )
        let response: APIResponse<CaptureDetailDTO> = try await networkClient.send(endpoint)
        return CardSnapshot(detailDTO: try response.requiredData())
    }

    func updateFavorite(captureID: Int64, isFavorite: Bool) async throws {
        let endpoint = try jsonEndpoint(
            method: .patch,
            path: "/api/v1/captures/\(captureID)/favorite",
            payload: FavoriteRequestDTO(isFavorite: isFavorite)
        )
        let _: EmptyResponse = try await networkClient.send(endpoint)
    }

    func updateCapture(captureID: Int64, draft: CardEditDraft) async throws {
        guard let cardType = CardTypeCode(category: draft.category) else {
            throw APIError.malformedRequest
        }
        let normalizedDraft = draft.normalized()
        let endpoint = try jsonEndpoint(
            method: .patch,
            path: "/api/v1/captures/\(captureID)",
            payload: CaptureUpdateRequestDTO(
                title: normalizedDraft.title,
                summary: normalizedDraft.summary,
                body: normalizedDraft.body,
                cardType: cardType
            )
        )
        let _: EmptyResponse = try await networkClient.send(endpoint)
    }

    func deleteCapture(captureID: Int64) async throws {
        let endpoint = APIEndpoint(
            method: .delete,
            path: "/api/v1/captures/\(captureID)",
            authorization: .bearer
        )
        let _: EmptyResponse = try await networkClient.send(endpoint)
    }

    func deleteCaptures(captureIDs: [Int64]) async throws {
        guard !captureIDs.isEmpty else { return }
        let endpoint = try jsonEndpoint(
            method: .post,
            path: "/api/v1/captures/bulk-delete",
            payload: BulkDeleteRequestDTO(captureIds: captureIDs)
        )
        let _: EmptyResponse = try await networkClient.send(endpoint)
    }

    func reportCapture(
        captureID: Int64,
        reason: CaptureReportReason,
        detail: String? = nil
    ) async throws {
        let endpoint = try jsonEndpoint(
            method: .post,
            path: "/api/v1/captures/\(captureID)/report",
            payload: CaptureReportRequestDTO(reason: reason, detail: detail)
        )
        let _: EmptyResponse = try await networkClient.send(endpoint)
    }

    private func jsonEndpoint<Payload: Encodable>(
        method: APIEndpoint.Method,
        path: String,
        payload: Payload
    ) throws -> APIEndpoint {
        let data: Data
        do {
            data = try encoder.encode(payload)
        } catch {
            throw APIError.malformedRequest
        }

        return APIEndpoint(
            method: method,
            path: path,
            headers: ["Content-Type": "application/json", "Accept": "application/json"],
            body: .json(data),
            authorization: .bearer
        )
    }
}

nonisolated enum CaptureLifecycleError: Error, Equatable, Sendable {
    case invalidImageCount
    case uploadCountMismatch
    case uploadFailed
    case pollingTimedOut
    case missingCaptureID
}

extension CardSnapshot {
    nonisolated init(detailDTO dto: CaptureDetailDTO) {
        self.init(
            captureID: dto.captureId,
            title: dto.title,
            summary: dto.summary,
            category: dto.typeCode.category,
            organizedAt: dto.organizedAt,
            location: "",
            businessHours: "",
            confirmationLabel: nil,
            memo: dto.body,
            tags: [],
            originalImageURL: dto.originalImageUrl,
            thumbnailURL: dto.originalImageUrl,
            isFavorite: dto.isFavorite
        )
    }
}
