import Foundation

final class AuthenticatedNetworkClient: NetworkClient, @unchecked Sendable {
    typealias AccessTokenProvider = @MainActor @Sendable () throws -> String
    typealias SessionRefresher = @MainActor @Sendable () async throws -> ServerTokenRecord
    typealias SessionInvalidationHandler = @MainActor @Sendable () -> Void

    private let networkClient: any NetworkClient
    private let accessTokenProvider: AccessTokenProvider
    private let sessionRefresher: SessionRefresher
    private let sessionInvalidationHandler: SessionInvalidationHandler

    init(
        networkClient: any NetworkClient,
        accessTokenProvider: @escaping AccessTokenProvider,
        sessionRefresher: @escaping SessionRefresher,
        sessionInvalidationHandler: @escaping SessionInvalidationHandler
    ) {
        self.networkClient = networkClient
        self.accessTokenProvider = accessTokenProvider
        self.sessionRefresher = sessionRefresher
        self.sessionInvalidationHandler = sessionInvalidationHandler
    }

    nonisolated func send<Response: Decodable>(
        _ endpoint: APIEndpoint,
        as responseType: Response.Type
    ) async throws -> Response {
        guard endpoint.authorization == .bearer else {
            return try await networkClient.send(endpoint, as: responseType)
        }

        let accessToken: String
        do {
            accessToken = try await accessTokenProvider()
        } catch {
            await sessionInvalidationHandler()
            throw error
        }

        do {
            return try await networkClient.send(
                endpoint.withBearerToken(accessToken),
                as: responseType
            )
        } catch let error as APIError where error.isUnauthorized {
            return try await refreshAndRetry(endpoint, as: responseType)
        }
    }

    private nonisolated func refreshAndRetry<Response: Decodable>(
        _ endpoint: APIEndpoint,
        as responseType: Response.Type
    ) async throws -> Response {
        let refreshedToken: ServerTokenRecord
        do {
            refreshedToken = try await sessionRefresher()
        } catch {
            await sessionInvalidationHandler()
            throw error
        }

        do {
            return try await networkClient.send(
                endpoint.withBearerToken(refreshedToken.accessToken),
                as: responseType
            )
        } catch let error as APIError where error.isUnauthorized {
            await sessionInvalidationHandler()
            throw error
        }
    }
}

private extension APIEndpoint {
    func withBearerToken(_ token: String) -> APIEndpoint {
        addingHeader(name: "Authorization", value: "Bearer \(token)")
    }
}

private extension APIError {
    var isUnauthorized: Bool {
        guard case .statusCode(let statusCode, _, _) = self else {
            return false
        }
        return statusCode == 401
    }
}
