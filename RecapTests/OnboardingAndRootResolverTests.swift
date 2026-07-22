import XCTest
@testable import Recap

final class AppLaunchDestinationResolverTests: XCTestCase {
    private let token = ServerTokenRecord(
        accessToken: "access",
        refreshToken: "refresh",
        accessTokenExpiresAt: .distantFuture
    )

    func testLaunchAndSignOutDestinations() {
        XCTAssertEqual(resolve(.launching, .notStarted), .launching)
        XCTAssertEqual(resolve(.signingOut, .completed), .launching)
        XCTAssertEqual(resolve(.signedOut(nil), .notStarted), .serviceIntro)
        XCTAssertEqual(resolve(.signedOut(.sessionExpired), .completed), .login(.sessionExpired))
        XCTAssertEqual(resolve(.authenticating(.apple), .completed), .login(nil))
    }

    func testAuthenticatedOnboardingDestinations() {
        XCTAssertEqual(resolve(.authenticated(token), .notStarted), .permissionGuide)
        XCTAssertEqual(resolve(.authenticated(token), .loginReady), .permissionGuide)
        XCTAssertEqual(resolve(.authenticated(token), .permissionGuide), .permissionGuide)
        XCTAssertEqual(resolve(.authenticated(token), .shareSetup), .shareSetup)
        XCTAssertEqual(resolve(.authenticated(token), .shareSetupDetail), .shareSetupDetail)
        XCTAssertEqual(resolve(.authenticated(token), .firstCardCreation), .firstCardCreation)
        XCTAssertEqual(resolve(.authenticated(token), .completed), .main)
    }

    private func resolve(
        _ session: RecapSessionState,
        _ onboarding: OnboardingProgress
    ) -> AppLaunchDestination {
        AppLaunchDestinationResolver.resolve(
            sessionState: session,
            onboardingProgress: onboarding
        )
    }
}

@MainActor
final class OnboardingProgressStoreTests: XCTestCase {
    func testLoadFailureFallsBackWithoutChangingSessionState() {
        let token = ServerTokenRecord(
            accessToken: "access",
            refreshToken: "refresh",
            accessTokenExpiresAt: .distantFuture
        )
        let secureStore = ResolverSecureStoreStub(token: token)
        let sessionStore = RecapSessionStore(
            authenticationService: AuthenticationService(
                networkClient: ResolverNetworkClientStub(),
                secureSessionStore: secureStore
            ),
            secureSessionStore: secureStore,
            initialState: .authenticated(token)
        )
        let persistence = OnboardingPersistenceStub(loadError: .invalidStoredValue)

        let store = OnboardingProgressStore(persistence: persistence)

        XCTAssertEqual(store.progress, .notStarted)
        XCTAssertTrue(store.didFailToPersist)
        XCTAssertEqual(sessionStore.state, .authenticated(token))
    }

    func testProgressPersistsIndependentlyFromSession() {
        let persistence = OnboardingPersistenceStub(progress: .shareSetup)
        let store = OnboardingProgressStore(persistence: persistence)

        store.move(to: .completed)

        XCTAssertEqual(store.progress, .completed)
        XCTAssertEqual(persistence.progress, .completed)
    }
}

private final class ResolverNetworkClientStub: NetworkClient, @unchecked Sendable {
    func send<Response: Decodable>(
        _ endpoint: APIEndpoint,
        as responseType: Response.Type
    ) async throws -> Response {
        throw APIError.offline
    }
}

private final class ResolverSecureStoreStub: SecureSessionStoring {
    private var token: ServerTokenRecord?

    init(token: ServerTokenRecord?) { self.token = token }

    func deviceID() throws -> String { "device" }
    func saveServerTokenRecord(_ record: ServerTokenRecord) throws { token = record }
    func loadServerTokenRecord() throws -> ServerTokenRecord? { token }
    func deleteServerTokenRecord() throws { token = nil }
}

private final class OnboardingPersistenceStub: OnboardingProgressPersisting {
    var progress: OnboardingProgress?
    private let loadError: OnboardingProgressPersistenceError?

    init(
        progress: OnboardingProgress? = nil,
        loadError: OnboardingProgressPersistenceError? = nil
    ) {
        self.progress = progress
        self.loadError = loadError
    }

    func load() throws -> OnboardingProgress? {
        if let loadError { throw loadError }
        return progress
    }

    func save(_ progress: OnboardingProgress) throws { self.progress = progress }
}
