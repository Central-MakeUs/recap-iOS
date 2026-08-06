import Synchronization
import XCTest
@testable import Recap

@MainActor
final class AuthenticationServiceTests: XCTestCase {
    func testProviderCancellationDoesNotSendBackendRequest() async {
        let networkClient = AuthenticationNetworkClientSpy()
        let service = AuthenticationService(
            networkClient: networkClient,
            secureSessionStore: AuthenticationSecureStoreSpy()
        )

        do {
            _ = try await service.login(
                using: SocialLoginProviderStub(provider: .kakao, result: .failure(.cancelled))
            )
            XCTFail("Expected cancellation")
        } catch let error as SocialLoginError {
            XCTAssertEqual(error, .cancelled)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }

        XCTAssertEqual(networkClient.sendCount, 0)
    }

    func testProviderTokenIsSentToTheMatchingBackendEndpointAndStored() async throws {
        let expiry = Date(timeIntervalSince1970: 1_800)
        let networkClient = AuthenticationNetworkClientSpy(
            response: AuthLoginResponse(
                success: true,
                data: AuthTokenResponse(
                    accessToken: "server-access",
                    refreshToken: "server-refresh",
                    accessTokenExpiresAt: expiry
                )
            )
        )
        let secureStore = AuthenticationSecureStoreSpy(deviceID: "installation-id")
        let service = AuthenticationService(
            networkClient: networkClient,
            secureSessionStore: secureStore
        )

        let record = try await service.login(
            using: SocialLoginProviderStub(provider: .apple, result: .success("provider-jwt"))
        )

        let request = try XCTUnwrap(networkClient.lastEndpoint).urlRequest(
            baseURL: URL(string: "https://re-cap.duckdns.org")!
        )
        let body = try XCTUnwrap(request.httpBody)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: String])

        XCTAssertEqual(request.url?.path, "/api/v1/auth/oauth/apple/login")
        XCTAssertEqual(json["deviceId"], "installation-id")
        XCTAssertEqual(json["providerToken"], "provider-jwt")
        XCTAssertEqual(json["platform"], "IOS")
        XCTAssertEqual(secureStore.savedRecord, record)
    }

    func testStorageFailurePreventsSuccessAndCleansPartialTokenRecord() async {
        let networkClient = AuthenticationNetworkClientSpy(
            response: AuthLoginResponse(
                success: true,
                data: AuthTokenResponse(
                    accessToken: "server-access",
                    refreshToken: "server-refresh",
                    accessTokenExpiresAt: Date(timeIntervalSince1970: 1_800)
                )
            )
        )
        let secureStore = AuthenticationSecureStoreSpy(saveError: .keychain(status: errSecNotAvailable))
        let service = AuthenticationService(
            networkClient: networkClient,
            secureSessionStore: secureStore
        )

        do {
            _ = try await service.login(
                using: SocialLoginProviderStub(provider: .kakao, result: .success("provider-token"))
            )
            XCTFail("Expected storage failure")
        } catch let error as SecureStorageError {
            XCTAssertEqual(error, .keychain(status: errSecNotAvailable))
        } catch {
            XCTFail("Unexpected error: \(error)")
        }

        XCTAssertNil(secureStore.savedRecord)
        XCTAssertEqual(secureStore.deleteCount, 1)
    }

    func testRefreshRotatesStoredTokensUsingCurrentRefreshToken() async throws {
        let currentToken = ServerTokenRecord(
            accessToken: "old-access",
            refreshToken: "old-refresh",
            accessTokenExpiresAt: .distantPast
        )
        let expiry = Date(timeIntervalSince1970: 3_600)
        let networkClient = AuthenticationNetworkClientSpy(
            response: AuthLoginResponse(
                success: true,
                data: AuthTokenResponse(
                    accessToken: "new-access",
                    refreshToken: "new-refresh",
                    accessTokenExpiresAt: expiry
                )
            )
        )
        let secureStore = AuthenticationSecureStoreSpy(token: currentToken)
        let service = AuthenticationService(
            networkClient: networkClient,
            secureSessionStore: secureStore
        )

        let refreshedToken = try await service.refreshSession()

        let request = try XCTUnwrap(networkClient.lastEndpoint).urlRequest(
            baseURL: URL(string: "https://re-cap.duckdns.org")!
        )
        let body = try XCTUnwrap(request.httpBody)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: String])

        XCTAssertEqual(request.url?.path, "/api/v1/auth/refresh")
        XCTAssertEqual(json["refreshToken"], "old-refresh")
        XCTAssertEqual(
            refreshedToken,
            ServerTokenRecord(
                accessToken: "new-access",
                refreshToken: "new-refresh",
                accessTokenExpiresAt: expiry
            )
        )
        XCTAssertEqual(secureStore.savedRecord, refreshedToken)
    }

    func testRefreshStorageFailureDeletesRevokedTokenRecord() async {
        let currentToken = ServerTokenRecord(
            accessToken: "old-access",
            refreshToken: "old-refresh",
            accessTokenExpiresAt: .distantPast
        )
        let networkClient = AuthenticationNetworkClientSpy(
            response: AuthLoginResponse(
                success: true,
                data: AuthTokenResponse(
                    accessToken: "new-access",
                    refreshToken: "new-refresh",
                    accessTokenExpiresAt: .distantFuture
                )
            )
        )
        let secureStore = AuthenticationSecureStoreSpy(
            token: currentToken,
            saveError: .keychain(status: errSecNotAvailable)
        )
        let service = AuthenticationService(
            networkClient: networkClient,
            secureSessionStore: secureStore
        )

        do {
            _ = try await service.refreshSession()
            XCTFail("Expected storage failure")
        } catch let error as SecureStorageError {
            XCTAssertEqual(error, .keychain(status: errSecNotAvailable))
        } catch {
            XCTFail("Unexpected error: \(error)")
        }

        XCTAssertNil(secureStore.savedRecord)
        XCTAssertEqual(secureStore.deleteCount, 1)
    }

    func testLogoutSendsStoredRefreshTokenThenDeletesTokenRecord() async throws {
        let tokenRecord = ServerTokenRecord(
            accessToken: "access-token",
            refreshToken: "refresh-token",
            accessTokenExpiresAt: .distantFuture
        )
        let networkClient = AuthenticationNetworkClientSpy(
            response: AuthLogoutResponse(success: true)
        )
        let secureStore = AuthenticationSecureStoreSpy(token: tokenRecord)
        let service = AuthenticationService(
            networkClient: networkClient,
            secureSessionStore: secureStore
        )

        try await service.logout()

        let request = try XCTUnwrap(networkClient.lastEndpoint).urlRequest(
            baseURL: URL(string: "https://re-cap.duckdns.org")!
        )
        let body = try XCTUnwrap(request.httpBody)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: String])

        XCTAssertEqual(request.url?.path, "/api/v1/auth/logout")
        XCTAssertEqual(json["refreshToken"], "refresh-token")
        XCTAssertNil(secureStore.savedRecord)
        XCTAssertEqual(secureStore.deleteCount, 1)
    }

    func testLogoutFailureKeepsTokenRecordForRetry() async {
        let tokenRecord = ServerTokenRecord(
            accessToken: "access-token",
            refreshToken: "refresh-token",
            accessTokenExpiresAt: .distantFuture
        )
        let networkClient = AuthenticationNetworkClientSpy(error: APIError.offline)
        let secureStore = AuthenticationSecureStoreSpy(token: tokenRecord)
        let service = AuthenticationService(
            networkClient: networkClient,
            secureSessionStore: secureStore
        )

        do {
            try await service.logout()
            XCTFail("Expected logout failure")
        } catch let error as APIError {
            XCTAssertEqual(error, .offline)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }

        XCTAssertEqual(secureStore.savedRecord, tokenRecord)
        XCTAssertEqual(secureStore.deleteCount, 0)
    }

    func testLogoutWithoutStoredTokenDoesNotSendRequest() async throws {
        let networkClient = AuthenticationNetworkClientSpy()
        let service = AuthenticationService(
            networkClient: networkClient,
            secureSessionStore: AuthenticationSecureStoreSpy()
        )

        try await service.logout()

        XCTAssertEqual(networkClient.sendCount, 0)
    }
}

@MainActor
private final class SocialLoginProviderStub: SocialLoginProviding {
    let provider: AuthProvider
    private let result: Result<String, SocialLoginError>

    init(provider: AuthProvider, result: Result<String, SocialLoginError>) {
        self.provider = provider
        self.result = result
    }

    func providerToken() async throws -> String {
        try result.get()
    }
}

private final class AuthenticationNetworkClientSpy: NetworkClient {
    private struct State {
        var sendCount = 0
        var lastEndpoint: APIEndpoint?
    }

    private let state = Mutex(State())
    private let response: (any Sendable)?
    private let error: (any Error & Sendable)?

    var sendCount: Int { state.withLock(\.sendCount) }
    var lastEndpoint: APIEndpoint? { state.withLock(\.lastEndpoint) }

    init(response: (any Sendable)? = nil, error: (any Error & Sendable)? = nil) {
        self.response = response
        self.error = error
    }

    func send<Response: Decodable>(
        _ endpoint: APIEndpoint,
        as responseType: Response.Type
    ) async throws -> Response {
        state.withLock {
            $0.sendCount += 1
            $0.lastEndpoint = endpoint
        }

        if let error {
            throw error
        }

        guard let response = response as? Response else {
            throw APIError.decoding
        }
        return response
    }
}

private final class AuthenticationSecureStoreSpy: SecureSessionStoring {
    private let storedDeviceID: String
    private let saveError: SecureStorageError?

    var savedRecord: ServerTokenRecord?
    var deleteCount = 0

    init(
        deviceID: String = "device-id",
        token: ServerTokenRecord? = nil,
        saveError: SecureStorageError? = nil
    ) {
        self.storedDeviceID = deviceID
        self.savedRecord = token
        self.saveError = saveError
    }

    func deviceID() throws -> String {
        storedDeviceID
    }

    func saveServerTokenRecord(_ record: ServerTokenRecord) throws {
        if let saveError {
            throw saveError
        }
        savedRecord = record
    }

    func loadServerTokenRecord() throws -> ServerTokenRecord? {
        savedRecord
    }

    func deleteServerTokenRecord() throws {
        savedRecord = nil
        deleteCount += 1
    }
}
