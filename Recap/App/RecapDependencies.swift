import Foundation

@MainActor
final class RecapDependencies {
    let sessionStore: RecapSessionStore
    let onboardingProgressStore: OnboardingProgressStore
    let networkClient: any NetworkClient

    private let kakaoLoginProvider: any SocialLoginProviding
    private let appleLoginProvider: any SocialLoginProviding

    init(
        sessionStore: RecapSessionStore,
        onboardingProgressStore: OnboardingProgressStore,
        networkClient: any NetworkClient,
        kakaoLoginProvider: any SocialLoginProviding,
        appleLoginProvider: any SocialLoginProviding
    ) {
        self.sessionStore = sessionStore
        self.onboardingProgressStore = onboardingProgressStore
        self.networkClient = networkClient
        self.kakaoLoginProvider = kakaoLoginProvider
        self.appleLoginProvider = appleLoginProvider
    }

    func loginProvider(for provider: AuthProvider) -> any SocialLoginProviding {
        switch provider {
        case .kakao:
            return kakaoLoginProvider
        case .apple:
            return appleLoginProvider
        }
    }

    static func live(configuration: AppConfiguration) -> RecapDependencies {
        let secureSessionStore = KeychainSessionStore()
        let rawNetworkClient = AlamofireNetworkClient(
            configuration: NetworkConfiguration(baseURL: configuration.backendBaseURL),
            eventRecorder: { record in
                #if DEBUG
                print("[Recap.Network] \(record)")
                #endif
            }
        )
        let authenticationService = AuthenticationService(
            networkClient: rawNetworkClient,
            secureSessionStore: secureSessionStore
        )
        let sessionStore = RecapSessionStore(
            authenticationService: authenticationService,
            secureSessionStore: secureSessionStore
        )
        let authenticatedNetworkClient = AuthenticatedNetworkClient(
            networkClient: rawNetworkClient,
            accessTokenProvider: {
                try authenticationService.currentAccessToken()
            },
            sessionRefresher: {
                try await authenticationService.refreshSession()
            },
            sessionInvalidationHandler: {
                sessionStore.invalidateSessionAfterAuthorizationFailure()
            }
        )

        return RecapDependencies(
            sessionStore: sessionStore,
            onboardingProgressStore: OnboardingProgressStore(
                persistence: UserDefaultsOnboardingProgressPersistence()
            ),
            networkClient: authenticatedNetworkClient,
            kakaoLoginProvider: KakaoLoginProvider(),
            appleLoginProvider: AppleLoginProvider()
        )
    }

    static func preview(
        sessionState: RecapSessionState,
        onboardingProgress: OnboardingProgress
    ) -> RecapDependencies {
        let secureSessionStore = PreviewSecureSessionStore()
        let previewNetworkClient = PreviewNetworkClient()
        let authenticationService = AuthenticationService(
            networkClient: previewNetworkClient,
            secureSessionStore: secureSessionStore
        )

        return RecapDependencies(
            sessionStore: RecapSessionStore(
                authenticationService: authenticationService,
                secureSessionStore: secureSessionStore,
                initialState: sessionState
            ),
            onboardingProgressStore: OnboardingProgressStore(
                persistence: PreviewOnboardingProgressPersistence(onboardingProgress)
            ),
            networkClient: previewNetworkClient,
            kakaoLoginProvider: PreviewSocialLoginProvider(provider: .kakao),
            appleLoginProvider: PreviewSocialLoginProvider(provider: .apple)
        )
    }
}

private final class PreviewNetworkClient: NetworkClient, @unchecked Sendable {
    func send<Response: Decodable>(
        _ endpoint: APIEndpoint,
        as responseType: Response.Type
    ) async throws -> Response {
        throw APIError.offline
    }
}

private final class PreviewSecureSessionStore: SecureSessionStoring {
    func deviceID() throws -> String { "preview-device" }
    func saveServerTokenRecord(_ record: ServerTokenRecord) throws {}
    func loadServerTokenRecord() throws -> ServerTokenRecord? { nil }
    func deleteServerTokenRecord() throws {}
}

private final class PreviewOnboardingProgressPersistence: OnboardingProgressPersisting {
    private var progress: OnboardingProgress

    init(_ progress: OnboardingProgress) {
        self.progress = progress
    }

    func load() throws -> OnboardingProgress? { progress }
    func save(_ progress: OnboardingProgress) throws { self.progress = progress }
}

@MainActor
private final class PreviewSocialLoginProvider: SocialLoginProviding {
    let provider: AuthProvider

    init(provider: AuthProvider) {
        self.provider = provider
    }

    func providerToken() async throws -> String {
        throw SocialLoginError.unavailable
    }
}
