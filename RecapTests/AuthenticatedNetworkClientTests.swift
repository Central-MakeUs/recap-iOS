import Synchronization
import XCTest
@testable import Recap

@MainActor
final class AuthenticatedNetworkClientTests: XCTestCase {
    private struct Payload: Decodable, Equatable {
        let value: String
    }

    func testProtectedRequestAddsCurrentBearerToken() async throws {
        let rawClient = SequencedNetworkClientStub(results: [.success(Payload(value: "ok"))])
        let client = makeClient(rawClient: rawClient)

        let response: Payload = try await client.send(protectedEndpoint)

        XCTAssertEqual(response, Payload(value: "ok"))
        XCTAssertEqual(rawClient.requests.count, 1)
        XCTAssertEqual(rawClient.requests[0].headers["Authorization"], "Bearer old-access")
    }

    func testPublicRequestDoesNotReadTokenOrAddAuthorizationHeader() async throws {
        let rawClient = SequencedNetworkClientStub(results: [.success(Payload(value: "ok"))])
        var accessTokenReadCount = 0
        let client = makeClient(
            rawClient: rawClient,
            accessTokenProvider: {
                accessTokenReadCount += 1
                return "unexpected"
            }
        )

        let response: Payload = try await client.send(
            APIEndpoint(method: .get, path: "/api/v1/public")
        )

        XCTAssertEqual(response, Payload(value: "ok"))
        XCTAssertEqual(accessTokenReadCount, 0)
        XCTAssertNil(rawClient.requests[0].headers["Authorization"])
    }

    func testUnauthorizedRequestRefreshesAndRetriesOnceWithRotatedToken() async throws {
        let rawClient = SequencedNetworkClientStub(results: [
            .failure(APIError.statusCode(401, serverCode: "UNAUTHORIZED", message: nil)),
            .success(Payload(value: "retried"))
        ])
        var refreshCount = 0
        let client = makeClient(
            rawClient: rawClient,
            sessionRefresher: {
                refreshCount += 1
                return Self.refreshedToken
            }
        )

        let response: Payload = try await client.send(protectedEndpoint)

        XCTAssertEqual(response.value, "retried")
        XCTAssertEqual(refreshCount, 1)
        XCTAssertEqual(rawClient.requests.count, 2)
        XCTAssertEqual(rawClient.requests[0].headers["Authorization"], "Bearer old-access")
        XCTAssertEqual(rawClient.requests[1].headers["Authorization"], "Bearer new-access")
    }

    func testRefreshFailureInvalidatesSessionWithoutRetryingRequest() async {
        let rawClient = SequencedNetworkClientStub(results: [
            .failure(APIError.statusCode(401, serverCode: "UNAUTHORIZED", message: nil))
        ])
        var invalidationCount = 0
        let client = makeClient(
            rawClient: rawClient,
            sessionRefresher: { throw APIError.offline },
            sessionInvalidationHandler: { invalidationCount += 1 }
        )

        do {
            let _: Payload = try await client.send(protectedEndpoint)
            XCTFail("Expected refresh failure")
        } catch let error as APIError {
            XCTAssertEqual(error, .offline)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }

        XCTAssertEqual(rawClient.requests.count, 1)
        XCTAssertEqual(invalidationCount, 1)
    }

    func testSecondUnauthorizedResponseStopsAfterOneRetryAndInvalidatesSession() async {
        let rawClient = SequencedNetworkClientStub(results: [
            .failure(APIError.statusCode(401, serverCode: "UNAUTHORIZED", message: nil)),
            .failure(APIError.statusCode(401, serverCode: "UNAUTHORIZED", message: nil))
        ])
        var refreshCount = 0
        var invalidationCount = 0
        let client = makeClient(
            rawClient: rawClient,
            sessionRefresher: {
                refreshCount += 1
                return Self.refreshedToken
            },
            sessionInvalidationHandler: { invalidationCount += 1 }
        )

        do {
            let _: Payload = try await client.send(protectedEndpoint)
            XCTFail("Expected second unauthorized response")
        } catch let error as APIError {
            XCTAssertEqual(
                error,
                .statusCode(401, serverCode: "UNAUTHORIZED", message: nil)
            )
        } catch {
            XCTFail("Unexpected error: \(error)")
        }

        XCTAssertEqual(rawClient.requests.count, 2)
        XCTAssertEqual(refreshCount, 1)
        XCTAssertEqual(invalidationCount, 1)
    }

    private var protectedEndpoint: APIEndpoint {
        APIEndpoint(method: .get, path: "/api/v1/protected").authorized()
    }

    private func makeClient(
        rawClient: SequencedNetworkClientStub,
        accessTokenProvider: @escaping AuthenticatedNetworkClient.AccessTokenProvider = { "old-access" },
        sessionRefresher: AuthenticatedNetworkClient.SessionRefresher? = nil,
        sessionInvalidationHandler: @escaping AuthenticatedNetworkClient.SessionInvalidationHandler = {}
    ) -> AuthenticatedNetworkClient {
        AuthenticatedNetworkClient(
            networkClient: rawClient,
            accessTokenProvider: accessTokenProvider,
            sessionRefresher: sessionRefresher ?? { Self.refreshedToken },
            sessionInvalidationHandler: sessionInvalidationHandler
        )
    }

    private static let refreshedToken = ServerTokenRecord(
        accessToken: "new-access",
        refreshToken: "new-refresh",
        accessTokenExpiresAt: .distantFuture
    )
}

private final class SequencedNetworkClientStub: NetworkClient {
    typealias StubResult = Result<any Sendable, any Error & Sendable>

    private struct State {
        var results: [StubResult]
        var requests: [APIEndpoint] = []
    }

    private let state: Mutex<State>

    init(results: [StubResult]) {
        state = Mutex(State(results: results))
    }

    var requests: [APIEndpoint] {
        state.withLock(\.requests)
    }

    func send<Response: Decodable>(
        _ endpoint: APIEndpoint,
        as responseType: Response.Type
    ) async throws -> Response {
        let result = state.withLock { state -> StubResult in
            state.requests.append(endpoint)
            return state.results.removeFirst()
        }

        let value = try result.get()
        guard let response = value as? Response else {
            throw APIError.decoding
        }
        return response
    }
}
