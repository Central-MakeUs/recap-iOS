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
            response: AuthTokenResponse(
                accessToken: "server-access",
                refreshToken: "server-refresh",
                accessTokenExpiresAt: expiry
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
            response: AuthTokenResponse(
                accessToken: "server-access",
                refreshToken: "server-refresh",
                accessTokenExpiresAt: Date(timeIntervalSince1970: 1_800)
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

private final class AuthenticationNetworkClientSpy: NetworkClient, @unchecked Sendable {
    var sendCount = 0
    var lastEndpoint: APIEndpoint?
    private let response: Any?

    init(response: Any? = nil) {
        self.response = response
    }

    func send<Response: Decodable>(
        _ endpoint: APIEndpoint,
        as responseType: Response.Type
    ) async throws -> Response {
        sendCount += 1
        lastEndpoint = endpoint

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
        saveError: SecureStorageError? = nil
    ) {
        self.storedDeviceID = deviceID
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
