//
//  NetworkAuthenticationTests.swift
//  RecapTests
//

import Synchronization
import XCTest
@testable import Recap

@MainActor
final class NetworkAuthenticationTests: XCTestCase {
    override func tearDown() {
        StubURLProtocol.reset()
        super.tearDown()
    }

    func testKakaoLoginEndpointUsesContractPathBodyAndNoCachePolicy() throws {
        let endpoint = try AuthEndpoint.kakaoLogin(deviceId: "device-123", providerToken: "provider-token")
        let request = try endpoint.urlRequest(baseURL: URL(string: "https://re-cap.duckdns.org")!, requestID: "request-1")
        let body = try XCTUnwrap(request.httpBody)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: String])

        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.url?.path, "/api/v1/auth/oauth/kakao/login")
        XCTAssertEqual(request.cachePolicy, .reloadIgnoringLocalCacheData)
        XCTAssertEqual(json["deviceId"], "device-123")
        XCTAssertEqual(json["providerToken"], "provider-token")
        XCTAssertEqual(json["platform"], "IOS")
    }

    func testAppleLoginEndpointUsesContractPathBodyAndNoCachePolicy() throws {
        let endpoint = try AuthEndpoint.appleLogin(deviceId: "device-456", providerToken: "apple-token")
        let request = try endpoint.urlRequest(baseURL: URL(string: "https://re-cap.duckdns.org")!, requestID: "request-2")
        let body = try XCTUnwrap(request.httpBody)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: String])

        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.url?.path, "/api/v1/auth/oauth/apple/login")
        XCTAssertEqual(request.cachePolicy, .reloadIgnoringLocalCacheData)
        XCTAssertEqual(json["deviceId"], "device-456")
        XCTAssertEqual(json["providerToken"], "apple-token")
        XCTAssertEqual(json["platform"], "IOS")
    }

    func testLogoutEndpointUsesContractPathRefreshTokenAndNoCachePolicy() throws {
        let endpoint = try AuthEndpoint.logout(refreshToken: "refresh-token")
        let request = try endpoint.urlRequest(
            baseURL: URL(string: "https://re-cap.duckdns.org")!,
            requestID: "request-logout"
        )
        let body = try XCTUnwrap(request.httpBody)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: String])

        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.url?.path, "/api/v1/auth/logout")
        XCTAssertEqual(request.cachePolicy, .reloadIgnoringLocalCacheData)
        XCTAssertEqual(json["refreshToken"], "refresh-token")
    }

    func testRefreshEndpointUsesContractPathRefreshTokenAndNoCachePolicy() throws {
        let endpoint = try AuthEndpoint.refresh(refreshToken: "refresh-token")
        let request = try endpoint.urlRequest(
            baseURL: URL(string: "https://re-cap.duckdns.org")!,
            requestID: "request-refresh"
        )
        let body = try XCTUnwrap(request.httpBody)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: String])

        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.url?.path, "/api/v1/auth/refresh")
        XCTAssertEqual(request.cachePolicy, .reloadIgnoringLocalCacheData)
        XCTAssertEqual(json["refreshToken"], "refresh-token")
    }

    func testAlamofireNetworkClientDecodesRotatedRefreshResponse() async throws {
        StubURLProtocol.response = .http(
            statusCode: 200,
            body: """
            {
              "success": true,
              "data": {
                "accessToken": "new-access",
                "refreshToken": "new-refresh",
                "accessTokenExpiresAt": "2026-07-23T10:30:00Z"
              },
              "error": null
            }
            """.data(using: .utf8)!
        )

        let client = makeClient()
        let response: AuthLoginResponse = try await client.send(
            AuthEndpoint.refresh(refreshToken: "old-refresh")
        )

        XCTAssertEqual(response.data?.accessToken, "new-access")
        XCTAssertEqual(response.data?.refreshToken, "new-refresh")
    }

    func testAlamofireNetworkClientDecodesLogoutResponseWithNullData() async throws {
        StubURLProtocol.response = .http(
            statusCode: 200,
            body: #"{"success":true,"data":null,"error":null}"#.data(using: .utf8)!
        )

        let client = makeClient()
        let response: AuthLogoutResponse = try await client.send(
            AuthEndpoint.logout(refreshToken: "refresh-token")
        )

        XCTAssertTrue(response.success)
    }

    func testAlamofireNetworkClientDecodesISO8601AuthResponse() async throws {
        StubURLProtocol.response = .http(
            statusCode: 200,
            body: """
            {
              "success": true,
              "data": {
                "accessToken": "access-token",
                "refreshToken": "refresh-token",
                "accessTokenExpiresAt": "2026-07-13T10:30:00Z"
              },
              "error": null
            }
            """.data(using: .utf8)!
        )

        let client = makeClient()
        let response: AuthLoginResponse = try await client.send(
            AuthEndpoint.kakaoLogin(deviceId: "device", providerToken: "provider")
        )

        XCTAssertTrue(response.success)
        XCTAssertEqual(response.data?.accessToken, "access-token")
        XCTAssertEqual(response.data?.refreshToken, "refresh-token")
        XCTAssertEqual(
            response.data?.accessTokenExpiresAt,
            ISO8601DateFormatter().date(from: "2026-07-13T10:30:00Z")
        )
    }

    func testAPIResponseDecodesNullData() throws {
        let data = #"{"success":true,"data":null,"error":null}"#.data(using: .utf8)!

        let response = try JSONDecoder.recapAPI.decode(APIResponse<EmptyResponse>.self, from: data)

        XCTAssertTrue(response.success)
        XCTAssertNil(response.data)
        XCTAssertNil(response.error)
    }

    func testAlamofireNetworkClientAccepts204NoContent() async throws {
        StubURLProtocol.response = .http(statusCode: 204, body: Data())
        let client = makeClient()

        let response: EmptyResponse = try await client.send(
            APIEndpoint(method: .delete, path: "/api/v1/captures/1")
        )

        XCTAssertEqual(response, EmptyResponse())
    }

    @MainActor
    func testAuthenticatedClientRefreshesAndRetriesThroughURLProtocol() async throws {
        StubURLProtocol.responses = [
            .http(
                statusCode: 401,
                body: #"{"success":false,"data":null,"error":{"code":"UNAUTHORIZED","message":"expired"}}"#.data(using: .utf8)!
            ),
            .http(statusCode: 200, body: #"{"ok":true}"#.data(using: .utf8)!)
        ]

        struct Response: Decodable, Equatable {
            let ok: Bool
        }

        let client = AuthenticatedNetworkClient(
            networkClient: makeClient(),
            accessTokenProvider: { "expired-access" },
            sessionRefresher: {
                ServerTokenRecord(
                    accessToken: "refreshed-access",
                    refreshToken: "rotated-refresh",
                    accessTokenExpiresAt: .distantFuture
                )
            },
            sessionInvalidationHandler: {}
        )

        let response: Response = try await client.send(
            APIEndpoint(method: .get, path: "/api/v1/protected").authorized()
        )

        XCTAssertTrue(response.ok)
        XCTAssertEqual(StubURLProtocol.requests.count, 2)
        XCTAssertEqual(
            StubURLProtocol.requests[0].value(forHTTPHeaderField: "Authorization"),
            "Bearer expired-access"
        )
        XCTAssertEqual(
            StubURLProtocol.requests[1].value(forHTTPHeaderField: "Authorization"),
            "Bearer refreshed-access"
        )
    }

    func testKnownOAuthVerificationFailureEnvelopeIsNormalized() async throws {
        StubURLProtocol.response = .http(
            statusCode: 401,
            body: """
            {
              "success": false,
              "data": null,
              "error": {
                "code": "OAUTH_VERIFICATION_FAILED",
                "message": "invalid provider token"
              }
            }
            """.data(using: .utf8)!
        )

        let client = makeClient()

        do {
            let _: AuthTokenResponse = try await client.send(
                AuthEndpoint.appleLogin(deviceId: "device", providerToken: "bad-token")
            )
            XCTFail("Expected oauth verification failure")
        } catch let error as APIError {
            XCTAssertEqual(error, .oauthVerificationFailed(statusCode: 401))
        }
    }

    func testMalformedNonHTTPTimeoutOfflineAndStatusErrorsAreNormalized() async throws {
        let client = makeClient()

        do {
            let endpoint = try APIEndpoint.postJSON(path: "/malformed", body: ["value": Double.nan])
            let _: AuthTokenResponse = try await client.send(endpoint)
            XCTFail("Expected malformed request")
        } catch let error as APIError {
            XCTAssertEqual(error, .malformedRequest)
        }

        StubURLProtocol.response = .nonHTTP(body: Data())
        do {
            let _: AuthTokenResponse = try await client.send(
                AuthEndpoint.kakaoLogin(deviceId: "device", providerToken: "token")
            )
            XCTFail("Expected non-HTTP response")
        } catch let error as APIError {
            XCTAssertEqual(error, .nonHTTPResponse)
        }

        StubURLProtocol.response = .failure(URLError(.timedOut))
        do {
            let _: AuthTokenResponse = try await client.send(
                AuthEndpoint.kakaoLogin(deviceId: "device", providerToken: "token")
            )
            XCTFail("Expected timeout")
        } catch let error as APIError {
            XCTAssertEqual(error, .timeout)
        }

        StubURLProtocol.response = .failure(URLError(.notConnectedToInternet))
        do {
            let _: AuthTokenResponse = try await client.send(
                AuthEndpoint.kakaoLogin(deviceId: "device", providerToken: "token")
            )
            XCTFail("Expected offline")
        } catch let error as APIError {
            XCTAssertEqual(error, .offline)
        }

        StubURLProtocol.response = .failure(URLError(.secureConnectionFailed))
        do {
            let _: AuthTokenResponse = try await client.send(
                AuthEndpoint.kakaoLogin(deviceId: "device", providerToken: "token")
            )
            XCTFail("Expected transport error")
        } catch let error as APIError {
            XCTAssertEqual(error, .transport)
        }

        StubURLProtocol.response = .http(
            statusCode: 500,
            body: #"{"code":"SERVER_BUSY","message":"잠시 후 다시 시도해주세요"}"#.data(using: .utf8)!
        )
        do {
            let _: AuthTokenResponse = try await client.send(
                AuthEndpoint.kakaoLogin(deviceId: "device", providerToken: "token")
            )
            XCTFail("Expected status error")
        } catch let error as APIError {
            XCTAssertEqual(
                error,
                .statusCode(
                    500,
                    serverCode: "SERVER_BUSY",
                    message: "잠시 후 다시 시도해주세요"
                )
            )
        }
    }

    func testURLCacheSeamAndAuthNoCachePolicyAreAppliedToRequests() async throws {
        let cache = URLCache(memoryCapacity: 256_000, diskCapacity: 0)
        let configuration = NetworkConfiguration(
            baseURL: URL(string: "https://example.test")!,
            urlCache: cache
        )
        let urlSessionConfiguration = configuration.urlSessionConfiguration(protocolClasses: [StubURLProtocol.self])

        StubURLProtocol.response = .http(
            statusCode: 200,
            headers: ["Cache-Control": "public, max-age=3600"],
            body: """
            {
              "accessToken": "access-token",
              "refreshToken": "refresh-token",
              "accessTokenExpiresAt": "2026-07-13T10:30:00Z"
            }
            """.data(using: .utf8)!
        )

        let client = AlamofireNetworkClient(
            configuration: configuration,
            urlSessionConfiguration: urlSessionConfiguration
        )
        let _: AuthTokenResponse = try await client.send(
            AuthEndpoint.appleLogin(deviceId: "device", providerToken: "provider")
        )

        XCTAssertIdentical(urlSessionConfiguration.urlCache, cache)
        XCTAssertEqual(StubURLProtocol.lastRequest?.cachePolicy, .reloadIgnoringLocalCacheData)
    }

    func testRedactedNetworkLogRecordOmitsBodyHeadersAndTokens() async throws {
        let token = "sensitive-provider-token"
        let expectation = expectation(description: "network log record")
        let records = NetworkLogRecordCollector()

        StubURLProtocol.response = .http(
            statusCode: 200,
            body: """
            {
              "accessToken": "access-token",
              "refreshToken": "refresh-token",
              "accessTokenExpiresAt": "2026-07-13T10:30:00Z"
            }
            """.data(using: .utf8)!
        )

        let client = makeClient { record in
            records.append(record)
            expectation.fulfill()
        }

        let _: AuthTokenResponse = try await client.send(
            AuthEndpoint.kakaoLogin(deviceId: "device", providerToken: token)
        )
        await fulfillment(of: [expectation], timeout: 2)

        let record = try XCTUnwrap(records.all.last)
        XCTAssertEqual(record.url?.absoluteString, "https://example.test/api/v1/auth/oauth/kakao/login")
        XCTAssertEqual(record.statusCode, 200)
        XCTAssertNotNil(record.requestID)
        XCTAssertFalse(record.description.contains(token))
        XCTAssertFalse(record.description.contains("access-token"))
        XCTAssertFalse(record.description.localizedCaseInsensitiveContains("authorization"))
        XCTAssertFalse(record.description.localizedCaseInsensitiveContains("content-type"))
    }

    func testGenericEndpointSupportsNonAuthDecodableResponse() async throws {
        struct EchoResponse: Decodable, Equatable {
            let ok: Bool
        }

        StubURLProtocol.response = .http(statusCode: 200, body: #"{"ok":true}"#.data(using: .utf8)!)

        let endpoint = APIEndpoint(
            method: .get,
            path: "/api/v1/ping",
            queryItems: [URLQueryItem(name: "source", value: "test")],
            headers: ["X-Feature": "network-contract"],
            cachePolicy: .useProtocolCachePolicy
        )

        let client = makeClient()
        let response: EchoResponse = try await client.send(endpoint)

        XCTAssertEqual(response, EchoResponse(ok: true))
        XCTAssertEqual(StubURLProtocol.lastRequest?.url?.path, "/api/v1/ping")
        XCTAssertEqual(StubURLProtocol.lastRequest?.url?.query, "source=test")
        XCTAssertEqual(StubURLProtocol.lastRequest?.value(forHTTPHeaderField: "X-Feature"), "network-contract")
    }

    private func makeClient(
        eventRecorder: @escaping @Sendable (NetworkLogRecord) -> Void = { _ in }
    ) -> AlamofireNetworkClient {
        let configuration = NetworkConfiguration(baseURL: URL(string: "https://example.test")!)

        return AlamofireNetworkClient(
            configuration: configuration,
            urlSessionConfiguration: configuration.urlSessionConfiguration(protocolClasses: [StubURLProtocol.self]),
            eventRecorder: eventRecorder
        )
    }
}

/// 로그 기록을 잠금으로 보호해 동시 실행 클로저에서 안전하게 모은다.
private final class NetworkLogRecordCollector: @unchecked Sendable {
    private let lock = NSLock()
    private var storage: [NetworkLogRecord] = []

    func append(_ record: NetworkLogRecord) {
        lock.withLock { storage.append(record) }
    }

    var all: [NetworkLogRecord] {
        lock.withLock { storage }
    }
}

private final class StubURLProtocol: URLProtocol {
    enum Response {
        case http(statusCode: Int, headers: [String: String] = [:], body: Data)
        case nonHTTP(body: Data)
        case failure(Error)
    }

    /// URL 로딩 스레드에서 병렬로 호출되므로 상태를 통째로 잠금 뒤에 둔다.
    private struct State {
        var response: Response = .http(statusCode: 200, body: Data())
        var queued: [Response] = []
        var lastRequest: URLRequest?
        var requests: [URLRequest] = []
    }

    private static let state = Mutex(State())

    static var response: Response {
        get { state.withLock(\.response) }
        set {
            state.withLock {
                $0.response = newValue
                $0.queued = [newValue]
            }
        }
    }

    static var responses: [Response] {
        get { state.withLock(\.queued) }
        set {
            state.withLock {
                $0.queued = newValue
                if let last = newValue.last { $0.response = last }
            }
        }
    }

    static var lastRequest: URLRequest? {
        state.withLock(\.lastRequest)
    }

    static var requests: [URLRequest] {
        state.withLock(\.requests)
    }

    static func reset() {
        state.withLock { $0 = State() }
    }

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        let response = Self.state.withLock { state -> Response in
            state.lastRequest = request
            state.requests.append(request)
            return state.queued.isEmpty ? state.response : state.queued.removeFirst()
        }

        switch response {
        case let .http(statusCode, headers, body):
            let url = request.url ?? URL(string: "https://example.test")!
            let response = HTTPURLResponse(
                url: url,
                statusCode: statusCode,
                httpVersion: "HTTP/1.1",
                headerFields: headers
            )!
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .allowed)
            client?.urlProtocol(self, didLoad: body)
            client?.urlProtocolDidFinishLoading(self)
        case let .nonHTTP(body):
            let url = request.url ?? URL(string: "https://example.test")!
            let response = URLResponse(
                url: url,
                mimeType: "application/json",
                expectedContentLength: body.count,
                textEncodingName: "utf-8"
            )
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: body)
            client?.urlProtocolDidFinishLoading(self)
        case let .failure(error):
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}
