import XCTest
@testable import Recap

@MainActor
final class RecapSessionStoreTests: XCTestCase {
    private let validToken = ServerTokenRecord(
        accessToken: "access",
        refreshToken: "refresh",
        accessTokenExpiresAt: Date(timeIntervalSince1970: 2_000)
    )

    func testRestoreWithValidTokenAuthenticates() {
        let secureStore = SessionSecureStoreStub(token: validToken)
        let store = makeStore(secureStore: secureStore)

        store.restore(now: Date(timeIntervalSince1970: 1_000))

        XCTAssertEqual(store.state, .authenticated(validToken))
    }

    func testRestoreWithoutTokenSignsOut() {
        let store = makeStore(secureStore: SessionSecureStoreStub())

        store.restore()

        XCTAssertEqual(store.state, .signedOut(nil))
    }

    func testRestoreWithExpiredTokenDeletesItAndReportsExpiry() {
        let secureStore = SessionSecureStoreStub(token: validToken)
        let store = makeStore(secureStore: secureStore)

        store.restore(now: Date(timeIntervalSince1970: 1_990))

        XCTAssertEqual(store.state, .signedOut(.sessionExpired))
        XCTAssertNil(secureStore.token)
        XCTAssertEqual(secureStore.deleteCount, 1)
    }

    func testLoginSuccessAuthenticates() async {
        let secureStore = SessionSecureStoreStub()
        let store = makeStore(secureStore: secureStore, response: validToken)

        let outcome = await store.login(using: SessionLoginProviderStub())

        XCTAssertEqual(outcome, .success)
        XCTAssertEqual(store.state, .authenticated(validToken))
    }

    func testProviderCancellationDoesNotReportFailure() async {
        let store = makeStore(secureStore: SessionSecureStoreStub())

        let outcome = await store.login(
            using: SessionLoginProviderStub(error: SocialLoginError.cancelled)
        )

        XCTAssertEqual(outcome, .cancelled)
        XCTAssertEqual(store.state, .signedOut(nil))
    }

    func testDuplicateLoginAttemptsOnlySendOneRequest() async {
        let gate = SessionLoginGate()
        let provider = SessionLoginProviderStub(gate: gate)
        let network = SessionNetworkClientStub(loginResponse: validToken)
        let secureStore = SessionSecureStoreStub()
        let store = makeStore(secureStore: secureStore, network: network)

        let first = Task { await store.login(using: provider) }
        await gate.waitUntilStarted()
        let duplicateOutcome = await store.login(using: provider)
        await gate.resume()
        _ = await first.value

        XCTAssertEqual(provider.requestCount, 1)
        XCTAssertEqual(network.sendCount, 1)
        XCTAssertEqual(duplicateOutcome, .ignored)
    }

    func testLogoutRevokesServerSessionDeletesTokenAndKeepsDeviceID() async {
        let secureStore = SessionSecureStoreStub(token: validToken, deviceID: "installation")
        let network = SessionNetworkClientStub(loginResponse: nil)
        let store = makeStore(
            secureStore: secureStore,
            network: network,
            initialState: .authenticated(validToken)
        )

        let outcome = await store.logout()

        XCTAssertEqual(outcome, .success)
        XCTAssertEqual(store.state, .signedOut(nil))
        XCTAssertNil(secureStore.token)
        XCTAssertEqual(try secureStore.deviceID(), "installation")
        XCTAssertEqual(network.logoutSendCount, 1)
    }

    func testLogoutFailureKeepsAuthenticatedSession() async {
        let secureStore = SessionSecureStoreStub(token: validToken)
        let network = SessionNetworkClientStub(loginResponse: nil, logoutError: APIError.offline)
        let store = makeStore(
            secureStore: secureStore,
            network: network,
            initialState: .authenticated(validToken)
        )

        let outcome = await store.logout()

        XCTAssertEqual(outcome, .failure)
        XCTAssertEqual(store.state, .authenticated(validToken))
        XCTAssertEqual(secureStore.token, validToken)
        XCTAssertEqual(secureStore.deleteCount, 0)
    }

    func testLogoutDuringLoginPreventsLateAuthentication() async {
        let gate = SessionLoginGate()
        let secureStore = SessionSecureStoreStub()
        let network = SessionNetworkClientStub(loginResponse: validToken)
        let store = makeStore(secureStore: secureStore, network: network)
        let provider = SessionLoginProviderStub(gate: gate)

        let login = Task { await store.login(using: provider) }
        await gate.waitUntilStarted()
        _ = await store.logout()
        await gate.resume()
        _ = await login.value

        XCTAssertEqual(store.state, .signedOut(nil))
        XCTAssertNil(secureStore.token)
        XCTAssertEqual(network.sendCount, 0)
        XCTAssertEqual(secureStore.saveCount, 0)
    }

    private func makeStore(
        secureStore: SessionSecureStoreStub,
        response: ServerTokenRecord? = nil,
        network: SessionNetworkClientStub? = nil,
        initialState: RecapSessionState = .launching
    ) -> RecapSessionStore {
        let client = network ?? SessionNetworkClientStub(loginResponse: response)
        return RecapSessionStore(
            authenticationService: AuthenticationService(
                networkClient: client,
                secureSessionStore: secureStore
            ),
            secureSessionStore: secureStore,
            initialState: initialState
        )
    }
}

@MainActor
private final class SessionLoginProviderStub: SocialLoginProviding {
    let provider: AuthProvider = .kakao
    private let error: Error?
    private let gate: SessionLoginGate?
    private(set) var requestCount = 0

    init(error: Error? = nil, gate: SessionLoginGate? = nil) {
        self.error = error
        self.gate = gate
    }

    func providerToken() async throws -> String {
        requestCount += 1
        if let gate { await gate.suspend() }
        if let error { throw error }
        return "provider-token"
    }
}

private actor SessionLoginGate {
    private var continuation: CheckedContinuation<Void, Never>?
    private var started = false

    func suspend() async {
        started = true
        await withCheckedContinuation { continuation = $0 }
    }

    func waitUntilStarted() async {
        while !started { await Task.yield() }
    }

    func resume() {
        continuation?.resume()
        continuation = nil
    }
}

private final class SessionNetworkClientStub: NetworkClient, @unchecked Sendable {
    private let loginResponse: ServerTokenRecord?
    private let logoutError: Error?
    private(set) var sendCount = 0
    private(set) var logoutSendCount = 0

    init(loginResponse: ServerTokenRecord?, logoutError: Error? = nil) {
        self.loginResponse = loginResponse
        self.logoutError = logoutError
    }

    func send<Response: Decodable>(_ endpoint: APIEndpoint, as responseType: Response.Type) async throws -> Response {
        sendCount += 1

        if endpoint.path == "/api/v1/auth/logout" {
            logoutSendCount += 1
            if let logoutError { throw logoutError }
            guard let typed = AuthLogoutResponse(success: true) as? Response else {
                throw APIError.decoding
            }
            return typed
        }

        guard let loginResponse else { throw APIError.offline }
        let dto = AuthLoginResponse(
            success: true,
            data: AuthTokenResponse(
                accessToken: loginResponse.accessToken,
                refreshToken: loginResponse.refreshToken,
                accessTokenExpiresAt: loginResponse.accessTokenExpiresAt
            )
        )
        guard let typed = dto as? Response else { throw APIError.decoding }
        return typed
    }
}

private final class SessionSecureStoreStub: SecureSessionStoring {
    private let storedDeviceID: String
    var token: ServerTokenRecord?
    private(set) var deleteCount = 0
    private(set) var saveCount = 0

    init(token: ServerTokenRecord? = nil, deviceID: String = "device") {
        self.token = token
        self.storedDeviceID = deviceID
    }

    func deviceID() throws -> String { storedDeviceID }
    func saveServerTokenRecord(_ record: ServerTokenRecord) throws {
        token = record
        saveCount += 1
    }
    func loadServerTokenRecord() throws -> ServerTokenRecord? { token }
    func deleteServerTokenRecord() throws { token = nil; deleteCount += 1 }
}
