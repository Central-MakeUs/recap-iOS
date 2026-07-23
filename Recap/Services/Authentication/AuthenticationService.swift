import Foundation

@MainActor
final class AuthenticationService {
    private let networkClient: any NetworkClient
    private let secureSessionStore: any SecureSessionStoring
    private var refreshTask: Task<ServerTokenRecord, Error>?

    init(
        networkClient: any NetworkClient,
        secureSessionStore: any SecureSessionStoring
    ) {
        self.networkClient = networkClient
        self.secureSessionStore = secureSessionStore
    }

    @discardableResult
    func login(using provider: any SocialLoginProviding) async throws -> ServerTokenRecord {
        let providerToken = try await provider.providerToken()
        try Task.checkCancellation()

        let deviceID = try secureSessionStore.deviceID()
        let endpoint = try AuthEndpoint.login(
            provider: provider.provider,
            deviceId: deviceID,
            providerToken: providerToken
        )
        let response: AuthLoginResponse = try await networkClient.send(endpoint)
        try Task.checkCancellation()

        let responseData = try response.requiredData()

        let tokenRecord = ServerTokenRecord(
            accessToken: responseData.accessToken,
            refreshToken: responseData.refreshToken,
            accessTokenExpiresAt: responseData.accessTokenExpiresAt
        )

        do {
            try Task.checkCancellation()
            try secureSessionStore.saveServerTokenRecord(tokenRecord)
        } catch {
            try? secureSessionStore.deleteServerTokenRecord()
            throw error
        }

        return tokenRecord
    }

    func refreshSession() async throws -> ServerTokenRecord {
        if let refreshTask {
            return try await refreshTask.value
        }

        let task = Task { @MainActor [networkClient, secureSessionStore] in
            guard let currentToken = try secureSessionStore.loadServerTokenRecord() else {
                throw AuthenticationSessionError.missingRefreshToken
            }

            let endpoint = try AuthEndpoint.refresh(refreshToken: currentToken.refreshToken)
            let response: AuthLoginResponse = try await networkClient.send(endpoint)
            let responseData = try response.requiredData()
            let refreshedToken = ServerTokenRecord(
                accessToken: responseData.accessToken,
                refreshToken: responseData.refreshToken,
                accessTokenExpiresAt: responseData.accessTokenExpiresAt
            )

            do {
                try secureSessionStore.saveServerTokenRecord(refreshedToken)
            } catch {
                try? secureSessionStore.deleteServerTokenRecord()
                throw error
            }

            return refreshedToken
        }

        refreshTask = task
        defer { refreshTask = nil }
        return try await task.value
    }

    func currentAccessToken() throws -> String {
        guard let tokenRecord = try secureSessionStore.loadServerTokenRecord() else {
            throw AuthenticationSessionError.missingRefreshToken
        }
        return tokenRecord.accessToken
    }

    func invalidateSession() {
        refreshTask?.cancel()
        refreshTask = nil
        try? secureSessionStore.deleteServerTokenRecord()
    }

    func logout() async throws {
        if let refreshTask {
            _ = try? await refreshTask.value
        }

        guard let tokenRecord = try secureSessionStore.loadServerTokenRecord() else {
            return
        }

        let endpoint = try AuthEndpoint.logout(refreshToken: tokenRecord.refreshToken)
        let response: AuthLogoutResponse = try await networkClient.send(endpoint)

        guard response.success else {
            throw APIError.decoding
        }

        try secureSessionStore.deleteServerTokenRecord()
    }
}

nonisolated enum AuthenticationSessionError: Error, Equatable, Sendable {
    case missingRefreshToken
}
