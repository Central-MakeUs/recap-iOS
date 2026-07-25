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
    let cardCreationProcessor: any CardCreationProcessing
    let cardDataInvalidationCenter: CardDataInvalidationCenter

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
        cardCreationProcessor: any CardCreationProcessing,
        cardDataInvalidationCenter: CardDataInvalidationCenter,
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
        self.cardCreationProcessor = cardCreationProcessor
        self.cardDataInvalidationCenter = cardDataInvalidationCenter
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
                persistence: UserDefaultsOnboardingProgressPersistence()
            ),
            networkClient: authenticatedNetworkClient,
            homeSummaryLoader: HomeSummaryService(networkClient: authenticatedNetworkClient),
            archiveLoader: ArchiveService(networkClient: authenticatedNetworkClient),
            searchLoader: SearchService(networkClient: authenticatedNetworkClient),
            captureService: captureService,
            cardCreationProcessor: CardCreationPipeline(
                captureService: captureService,
                imageUploader: URLSessionPresignedImageUploader()
            ),
            cardDataInvalidationCenter: CardDataInvalidationCenter(),
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
        let previewCaptureService = PreviewCaptureService()

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
            homeSummaryLoader: PreviewHomeSummaryLoader(),
            archiveLoader: PreviewArchiveLoader(),
            searchLoader: PreviewSearchLoader(),
            captureService: previewCaptureService,
            cardCreationProcessor: PreviewCardCreationPipeline(),
            cardDataInvalidationCenter: CardDataInvalidationCenter(),
            kakaoLoginProvider: PreviewSocialLoginProvider(provider: .kakao),
            appleLoginProvider: PreviewSocialLoginProvider(provider: .apple)
        )
    }
}

@MainActor
private final class PreviewHomeSummaryLoader: HomeSummaryLoading {
    func fetchSummary() async throws -> HomeSummaryContent {
        HomeSummaryContent(
            recentCards: SampleData.recentCards,
            favoriteCards: SampleData.cards.filter(\.isFavorite),
            frequentTypes: SampleData.collectionSummaries,
            hasAnyCapture: true
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
