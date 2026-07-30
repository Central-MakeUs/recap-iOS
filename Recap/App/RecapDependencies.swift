import Foundation

@MainActor
final class RecapDependencies {
    let sessionStore: RecapSessionStore
    let onboardingProgressStore: OnboardingProgressStore
    let networkClient: any NetworkClient
    let homeSummaryLoader: any HomeSummaryLoading
    let archiveLoader: any ArchiveLoading
    let searchLoader: any SearchLoading
    let captureService: any CaptureServing
    let userAccountService: any UserAccountServing
    let cardCreationProcessor: any CardCreationProcessing
    let cardDataInvalidationCenter: CardDataInvalidationCenter
    let organizeNotificationController: OrganizeNotificationController

    private let kakaoLoginProvider: any SocialLoginProviding
    private let appleLoginProvider: any SocialLoginProviding

    init(
        sessionStore: RecapSessionStore,
        onboardingProgressStore: OnboardingProgressStore,
        networkClient: any NetworkClient,
        homeSummaryLoader: any HomeSummaryLoading,
        archiveLoader: any ArchiveLoading,
        searchLoader: any SearchLoading,
        captureService: any CaptureServing,
        userAccountService: any UserAccountServing,
        cardCreationProcessor: any CardCreationProcessing,
        cardDataInvalidationCenter: CardDataInvalidationCenter,
        organizeNotificationController: OrganizeNotificationController,
        kakaoLoginProvider: any SocialLoginProviding,
        appleLoginProvider: any SocialLoginProviding
    ) {
        self.sessionStore = sessionStore
        self.onboardingProgressStore = onboardingProgressStore
        self.networkClient = networkClient
        self.homeSummaryLoader = homeSummaryLoader
        self.archiveLoader = archiveLoader
        self.searchLoader = searchLoader
        self.captureService = captureService
        self.userAccountService = userAccountService
        self.cardCreationProcessor = cardCreationProcessor
        self.cardDataInvalidationCenter = cardDataInvalidationCenter
        self.organizeNotificationController = organizeNotificationController
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
        let captureService = CaptureService(networkClient: authenticatedNetworkClient)

        return RecapDependencies(
            sessionStore: sessionStore,
            onboardingProgressStore: OnboardingProgressStore(
                persistence: InMemoryOnboardingProgressPersistence(.completed)
            ),
            networkClient: authenticatedNetworkClient,
            homeSummaryLoader: HomeSummaryService(networkClient: authenticatedNetworkClient),
            archiveLoader: ArchiveService(networkClient: authenticatedNetworkClient),
            searchLoader: SearchService(networkClient: authenticatedNetworkClient),
            captureService: captureService,
            userAccountService: UserAccountService(networkClient: authenticatedNetworkClient),
            cardCreationProcessor: CardCreationPipeline(
                captureService: captureService,
                imageUploader: URLSessionPresignedImageUploader()
            ),
            cardDataInvalidationCenter: CardDataInvalidationCenter(),
            organizeNotificationController: OrganizeNotificationController(),
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
        let cardRepository = PreviewCardRepository()
        let authenticationService = AuthenticationService(
            networkClient: previewNetworkClient,
            secureSessionStore: secureSessionStore
        )
        let previewCaptureService = PreviewCaptureService(cardRepository: cardRepository)

        return RecapDependencies(
            sessionStore: RecapSessionStore(
                authenticationService: authenticationService,
                secureSessionStore: secureSessionStore,
                initialState: sessionState
            ),
            onboardingProgressStore: OnboardingProgressStore(
                persistence: InMemoryOnboardingProgressPersistence(onboardingProgress)
            ),
            networkClient: previewNetworkClient,
            homeSummaryLoader: PreviewHomeSummaryLoader(cardRepository: cardRepository),
            archiveLoader: PreviewArchiveLoader(cardRepository: cardRepository),
            searchLoader: PreviewSearchLoader(cardRepository: cardRepository),
            captureService: previewCaptureService,
            userAccountService: PreviewUserAccountService(capturedCount: SampleData.cards.count),
            cardCreationProcessor: PreviewCardCreationPipeline(),
            cardDataInvalidationCenter: CardDataInvalidationCenter(),
            organizeNotificationController: OrganizeNotificationController(
                delivery: PreviewOrganizeNotificationDelivery(),
                userDefaults: UserDefaults(suiteName: UUID().uuidString)!
            ),
            kakaoLoginProvider: PreviewSocialLoginProvider(provider: .kakao),
            appleLoginProvider: PreviewSocialLoginProvider(provider: .apple)
        )
    }

    static func mock(
        initialSessionState: RecapSessionState = .signedOut(nil),
        onboardingProgress: OnboardingProgress = .notStarted
    ) -> RecapDependencies {
        let resolvedSessionState = initialSessionState
        let secureSessionStore = MockSecureSessionStore(
            tokenRecord: resolvedSessionState.tokenRecord
        )
        let networkClient = MockAuthenticationNetworkClient()
        let authenticationService = AuthenticationService(
            networkClient: networkClient,
            secureSessionStore: secureSessionStore
        )
        let cardRepository = PreviewCardRepository()
        let captureService = PreviewCaptureService(cardRepository: cardRepository)

        return RecapDependencies(
            sessionStore: RecapSessionStore(
                authenticationService: authenticationService,
                secureSessionStore: secureSessionStore,
                initialState: resolvedSessionState
            ),
            onboardingProgressStore: OnboardingProgressStore(
                persistence: InMemoryOnboardingProgressPersistence(onboardingProgress)
            ),
            networkClient: networkClient,
            homeSummaryLoader: PreviewHomeSummaryLoader(cardRepository: cardRepository),
            archiveLoader: PreviewArchiveLoader(cardRepository: cardRepository),
            searchLoader: PreviewSearchLoader(cardRepository: cardRepository),
            captureService: captureService,
            userAccountService: PreviewUserAccountService(
                capturedCount: SampleData.cards.count
            ),
            cardCreationProcessor: PreviewCardCreationPipeline(),
            cardDataInvalidationCenter: CardDataInvalidationCenter(),
            organizeNotificationController: OrganizeNotificationController(),
            kakaoLoginProvider: MockSocialLoginProvider(provider: .kakao),
            appleLoginProvider: MockSocialLoginProvider(provider: .apple)
        )
    }

    static func simulatorMock() -> RecapDependencies {
        mock(
            initialSessionState: .authenticated(
                ServerTokenRecord(
                    accessToken: "simulator-access-token",
                    refreshToken: "simulator-refresh-token",
                    accessTokenExpiresAt: .distantFuture
                )
            ),
            onboardingProgress: .notStarted
        )
    }
}

@MainActor
private final class PreviewHomeSummaryLoader: HomeSummaryLoading {
    private let cardRepository: PreviewCardRepository

    init(cardRepository: PreviewCardRepository = PreviewCardRepository()) {
        self.cardRepository = cardRepository
    }

    func fetchSummary() async throws -> HomeSummaryContent {
        let cards = await cardRepository.allCards()
        return HomeSummaryContent(
            recentCards: Array(cards.prefix(3)),
            favoriteCards: cards.filter(\.isFavorite),
            frequentTypes: SampleData.collectionSummaries,
            hasAnyCapture: !cards.isEmpty
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

private final class InMemoryOnboardingProgressPersistence: OnboardingProgressPersisting {
    private var progress: OnboardingProgress

    init(_ progress: OnboardingProgress) {
        self.progress = progress
    }

    func load() throws -> OnboardingProgress? { progress }
    func save(_ progress: OnboardingProgress) throws { self.progress = progress }
}

private final class MockSecureSessionStore: SecureSessionStoring {
    private var tokenRecord: ServerTokenRecord?

    init(tokenRecord: ServerTokenRecord? = nil) {
        self.tokenRecord = tokenRecord
    }

    func deviceID() throws -> String { "mock-device" }
    func saveServerTokenRecord(_ record: ServerTokenRecord) throws { tokenRecord = record }
    func loadServerTokenRecord() throws -> ServerTokenRecord? { tokenRecord }
    func deleteServerTokenRecord() throws { tokenRecord = nil }
}

private extension RecapSessionState {
    var tokenRecord: ServerTokenRecord? {
        guard case .authenticated(let tokenRecord) = self else { return nil }
        return tokenRecord
    }
}

private final class MockAuthenticationNetworkClient: NetworkClient, @unchecked Sendable {
    func send<Response: Decodable>(
        _ endpoint: APIEndpoint,
        as responseType: Response.Type
    ) async throws -> Response {
        let response: Any

        switch endpoint.path {
        case "/api/v1/auth/oauth/kakao/login",
             "/api/v1/auth/oauth/apple/login",
             "/api/v1/auth/refresh":
            response = AuthLoginResponse(
                success: true,
                data: AuthTokenResponse(
                    accessToken: "mock-access-token",
                    refreshToken: "mock-refresh-token",
                    accessTokenExpiresAt: .distantFuture
                )
            )
        case "/api/v1/auth/logout":
            response = AuthLogoutResponse(success: true)
        default:
            throw APIError.offline
        }

        guard let typedResponse = response as? Response else {
            throw APIError.decoding
        }
        return typedResponse
    }
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

@MainActor
private final class MockSocialLoginProvider: SocialLoginProviding {
    let provider: AuthProvider

    init(provider: AuthProvider) {
        self.provider = provider
    }

    func providerToken() async throws -> String {
        "mock-provider-token"
    }
}
