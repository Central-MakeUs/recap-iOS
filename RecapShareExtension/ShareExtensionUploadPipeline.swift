import Foundation
import OSLog
import Security

actor ShareExtensionUploadPipeline {
    private static let logger = Logger(
        subsystem: "com.cmc.recap.ShareExtension",
        category: "Upload"
    )

    private let baseURL: URL
    private let session: URLSession
    private let tokenStore: ShareExtensionTokenStore
    private let pollingInterval: Duration
    private let maximumPollingAttempts: Int
    private let encoder = JSONEncoder()
    private let decoder: JSONDecoder
    private var currentBatchID: Int64?

    init(
        baseURL: URL,
        session: URLSession = .shared,
        tokenStore: ShareExtensionTokenStore,
        pollingInterval: Duration = .seconds(1),
        maximumPollingAttempts: Int = 120
    ) {
        self.baseURL = baseURL
        self.session = session
        self.tokenStore = tokenStore
        self.pollingInterval = pollingInterval
        self.maximumPollingAttempts = maximumPollingAttempts

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder
    }

    nonisolated static func live(bundle: Bundle = .main) -> ShareExtensionUploadPipeline {
        let baseURLString = bundle.object(
            forInfoDictionaryKey: "BACKEND_BASE_URL"
        ) as? String
        let accessGroup = bundle.object(
            forInfoDictionaryKey: "KEYCHAIN_ACCESS_GROUP"
        ) as? String

        return ShareExtensionUploadPipeline(
            baseURL: URL(string: baseURLString ?? "") ?? URL(string: "https://re-cap.duckdns.org")!,
            tokenStore: ShareExtensionTokenStore(accessGroup: accessGroup)
        )
    }

    func organize(
        images: [Data],
        progress: @escaping @MainActor @Sendable (Double) -> Void
    ) async throws -> ShareOrganizeResult {
        guard (1...20).contains(images.count) else {
            throw ShareExtensionUploadError.invalidImageCount
        }

        await progress(0.05)
        let uploadResponse: ShareAPIEnvelope<ShareUploadURLsResponse> = try await sendAuthorized(
            method: "POST",
            path: "/api/v1/captures/upload-urls",
            body: ShareUploadURLsRequest(count: images.count)
        )
        guard let uploadItems = uploadResponse.data?.uploads,
              uploadItems.count == images.count else {
            throw ShareExtensionUploadError.invalidResponse
        }

        await progress(0.12)
        try await withThrowingTaskGroup(of: Void.self) { group in
            for (image, item) in zip(images, uploadItems) {
                group.addTask { [session] in
                    var request = URLRequest(url: item.uploadUrl)
                    request.httpMethod = "PUT"
                    request.setValue("image/jpeg", forHTTPHeaderField: "Content-Type")
                    let (_, response) = try await session.upload(for: request, from: image)
                    guard let httpResponse = response as? HTTPURLResponse else {
                        Self.logger.error("Presigned image upload returned a non-HTTP response")
                        throw ShareExtensionUploadError.invalidResponse
                    }
                    guard (200..<300).contains(httpResponse.statusCode) else {
                        Self.logger.error(
                            "Presigned image upload failed with status \(httpResponse.statusCode)"
                        )
                        throw ShareExtensionUploadError.uploadFailed(httpResponse.statusCode)
                    }
                }
            }

            var completedUploadCount = 0
            for try await _ in group {
                completedUploadCount += 1
                let uploadFraction = Double(completedUploadCount) / Double(images.count)
                await progress(0.12 + (0.43 * uploadFraction))
            }
        }
        try Task.checkCancellation()

        await progress(0.65)
        let organizeResponse: ShareAPIEnvelope<ShareOrganizeResponse> = try await sendAuthorized(
            method: "POST",
            path: "/api/v1/captures/organize",
            body: ShareOrganizeRequest(imageKeys: uploadItems.map(\.imageKey))
        )
        guard organizeResponse.success, let organize = organizeResponse.data else {
            throw ShareExtensionUploadError.invalidResponse
        }

        currentBatchID = organize.batchId
        defer { currentBatchID = nil }

        if organize.status.isTerminal {
            await progress(1)
            return ShareOrganizeResult(
                batchID: organize.batchId,
                status: organize.status,
                totalCount: organize.totalCount,
                successCount: organize.status == .completed ? organize.totalCount : 0,
                failureCount: organize.status == .failed ? organize.totalCount : 0
            )
        }

        for attempt in 0..<maximumPollingAttempts {
            try Task.checkCancellation()
            try await Task.sleep(for: pollingInterval)

            let envelope: ShareAPIEnvelope<ShareOrganizeStatusResponse> = try await sendAuthorized(
                method: "GET",
                path: "/api/v1/captures/organize/\(organize.batchId)/status"
            )
            guard let status = envelope.data else {
                throw ShareExtensionUploadError.invalidResponse
            }

            if status.status.isTerminal {
                await progress(1)
                return ShareOrganizeResult(
                    batchID: status.batchId,
                    status: status.status,
                    totalCount: status.totalCount,
                    successCount: status.successCount,
                    failureCount: status.failCount
                )
            }

            let pollingFraction = Double(attempt + 1) / Double(maximumPollingAttempts)
            await progress(0.7 + (0.25 * pollingFraction))
        }

        throw ShareExtensionUploadError.pollingTimedOut
    }

    func cancelCurrentProcess() async {
        guard let currentBatchID else { return }
        try? await sendAuthorizedNoContent(
            method: "POST",
            path: "/api/v1/captures/organize/\(currentBatchID)/cancel"
        )
        self.currentBatchID = nil
    }

    func acknowledge(batchID: Int64) async {
        try? await sendAuthorizedNoContent(
            method: "POST",
            path: "/api/v1/captures/organize/\(batchID)/ack"
        )
    }

    private func sendAuthorized<Response: Decodable, Body: Encodable>(
        method: String,
        path: String,
        body: Body
    ) async throws -> Response {
        var token = try tokenStore.load()
        let firstAttempt = try await send(
            method: method,
            path: path,
            body: body,
            accessToken: token.accessToken
        )

        if firstAttempt.statusCode == 401 {
            token = try await refresh(token: token)
            let retry = try await send(
                method: method,
                path: path,
                body: body,
                accessToken: token.accessToken
            )
            return try decode(Response.self, from: retry)
        }

        return try decode(Response.self, from: firstAttempt)
    }

    private func sendAuthorized<Response: Decodable>(
        method: String,
        path: String
    ) async throws -> Response {
        var token = try tokenStore.load()
        let firstAttempt = try await send(
            method: method,
            path: path,
            bodyData: nil,
            accessToken: token.accessToken
        )

        if firstAttempt.statusCode == 401 {
            token = try await refresh(token: token)
            let retry = try await send(
                method: method,
                path: path,
                bodyData: nil,
                accessToken: token.accessToken
            )
            return try decode(Response.self, from: retry)
        }

        return try decode(Response.self, from: firstAttempt)
    }

    private func sendAuthorizedNoContent(
        method: String,
        path: String
    ) async throws {
        var token = try tokenStore.load()
        var response = try await send(
            method: method,
            path: path,
            bodyData: nil,
            accessToken: token.accessToken
        )

        if response.statusCode == 401 {
            token = try await refresh(token: token)
            response = try await send(
                method: method,
                path: path,
                bodyData: nil,
                accessToken: token.accessToken
            )
        }

        guard (200..<300).contains(response.statusCode) else {
            throw ShareExtensionUploadError.httpStatus(response.statusCode)
        }
    }

    private func refresh(token: ShareServerTokenRecord) async throws -> ShareServerTokenRecord {
        let response = try await send(
            method: "POST",
            path: "/api/v1/auth/refresh",
            bodyData: try encoder.encode(
                ShareRefreshRequest(refreshToken: token.refreshToken)
            ),
            accessToken: nil
        )
        let envelope = try decode(
            ShareAPIEnvelope<ShareAuthTokenResponse>.self,
            from: response
        )
        guard let data = envelope.data else {
            throw ShareExtensionUploadError.invalidResponse
        }

        let refreshed = ShareServerTokenRecord(
            accessToken: data.accessToken,
            refreshToken: data.refreshToken,
            accessTokenExpiresAt: data.accessTokenExpiresAt
        )
        try tokenStore.save(refreshed)
        return refreshed
    }

    private func send<Body: Encodable>(
        method: String,
        path: String,
        body: Body,
        accessToken: String?
    ) async throws -> ShareHTTPResponse {
        try await send(
            method: method,
            path: path,
            bodyData: encoder.encode(body),
            accessToken: accessToken
        )
    }

    private func send(
        method: String,
        path: String,
        bodyData: Data?,
        accessToken: String?
    ) async throws -> ShareHTTPResponse {
        var request = URLRequest(url: baseURL.appending(path: path))
        request.httpMethod = method
        if bodyData != nil {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let accessToken {
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        }
        request.httpBody = bodyData

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            Self.logger.error("API request returned a non-HTTP response for \(path, privacy: .public)")
            throw ShareExtensionUploadError.invalidResponse
        }
        Self.logger.info(
            "API request completed path=\(path, privacy: .public) status=\(httpResponse.statusCode)"
        )
        return ShareHTTPResponse(statusCode: httpResponse.statusCode, data: data)
    }

    private func decode<Response: Decodable>(
        _ type: Response.Type,
        from response: ShareHTTPResponse
    ) throws -> Response {
        guard (200..<300).contains(response.statusCode) else {
            throw ShareExtensionUploadError.httpStatus(response.statusCode)
        }
        return try decoder.decode(type, from: response.data)
    }
}

struct ShareExtensionTokenStore: Sendable {
    private let accessGroup: String?
    private let service = "com.centralmakeus.recap.secure-storage"
    private let account = "server-token-record"

    init(accessGroup: String?) {
        self.accessGroup = accessGroup?.isEmpty == false ? accessGroup : nil
    }

    func load() throws -> ShareServerTokenRecord {
        var query = baseQuery
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else {
            throw ShareExtensionUploadError.missingSession
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(ShareServerTokenRecord.self, from: data)
    }

    func save(_ record: ShareServerTokenRecord) throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(record)
        let update = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ] as [String: Any]

        let status = SecItemUpdate(baseQuery as CFDictionary, update as CFDictionary)
        if status == errSecSuccess {
            return
        }
        guard status == errSecItemNotFound else {
            throw ShareExtensionUploadError.keychain(status)
        }

        var query = baseQuery
        query.merge(update) { _, new in new }
        let addStatus = SecItemAdd(query as CFDictionary, nil)
        guard addStatus == errSecSuccess else {
            throw ShareExtensionUploadError.keychain(addStatus)
        }
    }

    private var baseQuery: [String: Any] {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        if let accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }
        return query
    }
}

private struct ShareHTTPResponse {
    let statusCode: Int
    let data: Data
}

private struct ShareAPIEnvelope<Payload: Decodable>: Decodable {
    let success: Bool
    let data: Payload?
}

private struct ShareUploadURLsRequest: Encodable {
    let count: Int
}

private struct ShareUploadURLsResponse: Decodable {
    let uploads: [ShareUploadItem]
}

private struct ShareUploadItem: Decodable {
    let imageKey: String
    let uploadUrl: URL
}

private struct ShareOrganizeRequest: Encodable {
    let imageKeys: [String]
}

private struct ShareOrganizeResponse: Decodable {
    let batchId: Int64
    let totalCount: Int
    let status: ShareOrganizeStatus
}

private struct ShareOrganizeStatusResponse: Decodable {
    let batchId: Int64
    let status: ShareOrganizeStatus
    let totalCount: Int
    let successCount: Int
    let failCount: Int
}

private struct ShareRefreshRequest: Encodable {
    let refreshToken: String
}

private struct ShareAuthTokenResponse: Decodable {
    let accessToken: String
    let refreshToken: String
    let accessTokenExpiresAt: Date
}

struct ShareServerTokenRecord: Codable {
    let accessToken: String
    let refreshToken: String
    let accessTokenExpiresAt: Date
}

struct ShareOrganizeResult: Sendable {
    let batchID: Int64
    let status: ShareOrganizeStatus
    let totalCount: Int
    let successCount: Int
    let failureCount: Int
}

enum ShareOrganizeStatus: String, Decodable, Sendable {
    case processing = "PROCESSING"
    case completed = "COMPLETED"
    case partialFailed = "PARTIAL_FAILED"
    case failed = "FAILED"
    case cancelled = "CANCELLED"

    var isTerminal: Bool {
        self != .processing
    }
}

enum ShareExtensionUploadError: Error, Equatable {
    case missingSession
    case invalidImageCount
    case invalidResponse
    case uploadFailed(Int)
    case pollingTimedOut
    case httpStatus(Int)
    case keychain(OSStatus)
}
