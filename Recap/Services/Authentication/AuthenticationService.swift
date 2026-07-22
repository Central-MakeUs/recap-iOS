import Foundation

@MainActor
final class AuthenticationService {
    private let networkClient: any NetworkClient
    private let secureSessionStore: any SecureSessionStoring

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

        let tokenRecord = ServerTokenRecord(
            accessToken: response.data.accessToken,
            refreshToken: response.data.refreshToken,
            accessTokenExpiresAt: response.data.accessTokenExpiresAt
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

    func logout() async throws {
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
