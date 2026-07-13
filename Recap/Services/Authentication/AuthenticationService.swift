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
        let response: AuthTokenResponse = try await networkClient.send(endpoint)
        try Task.checkCancellation()

        let tokenRecord = ServerTokenRecord(
            accessToken: response.accessToken,
            refreshToken: response.refreshToken,
            accessTokenExpiresAt: response.accessTokenExpiresAt
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
}
