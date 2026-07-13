//
//  NetworkAuthenticationTests.swift
//  RecapTests
//

import XCTest
@testable import Recap

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

    func testAlamofireNetworkClientDecodesISO8601AuthResponse() async throws {
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

        let client = makeClient()
        let response: AuthTokenResponse = try await client.send(
            AuthEndpoint.kakaoLogin(deviceId: "device", providerToken: "provider")
        )

        XCTAssertEqual(response.accessToken, "access-token")
        XCTAssertEqual(response.refreshToken, "refresh-token")
        XCTAssertEqual(response.accessTokenExpiresAt, ISO8601DateFormatter().date(from: "2026-07-13T10:30:00Z"))
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
            body: #"{"code":"SERVER_BUSY"}"#.data(using: .utf8)!
        )
        do {
            let _: AuthTokenResponse = try await client.send(
                AuthEndpoint.kakaoLogin(deviceId: "device", providerToken: "token")
            )
            XCTFail("Expected status error")
        } catch let error as APIError {
            XCTAssertEqual(error, .statusCode(500, serverCode: "SERVER_BUSY"))
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
        var records: [NetworkLogRecord] = []

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

        let record = try XCTUnwrap(records.last)
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

private final class StubURLProtocol: URLProtocol {
    enum Response {
        case http(statusCode: Int, headers: [String: String] = [:], body: Data)
        case nonHTTP(body: Data)
        case failure(Error)
    }

    private static let lock = NSLock()
    private static var lockedResponse: Response = .http(statusCode: 200, body: Data())
    private static var lockedLastRequest: URLRequest?

    static var response: Response {
        get {
            lock.lock()
            defer { lock.unlock() }
            return lockedResponse
        }
        set {
            lock.lock()
            lockedResponse = newValue
            lock.unlock()
        }
    }

    static var lastRequest: URLRequest? {
        lock.lock()
        defer { lock.unlock() }
        return lockedLastRequest
    }

    static func reset() {
        lock.lock()
        lockedResponse = .http(statusCode: 200, body: Data())
        lockedLastRequest = nil
        lock.unlock()
    }

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        Self.lock.lock()
        Self.lockedLastRequest = request
        let response = Self.lockedResponse
        Self.lock.unlock()

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
