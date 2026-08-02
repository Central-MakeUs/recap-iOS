import XCTest
@testable import Recap

final class AppConfigurationTests: XCTestCase {
    func testBundledRuntimeProfileMatchesInfoPlist() throws {
        let bundledProfile = try XCTUnwrap(
            Bundle.main.object(forInfoDictionaryKey: "APP_RUNTIME_PROFILE") as? String
        )

        XCTAssertEqual(
            AppConfiguration.live().runtimeProfile.rawValue,
            bundledProfile
        )
    }

    func testInjectedRuntimeProfileIsPreserved() {
        let configuration = AppConfiguration(
            infoDictionary: ["APP_RUNTIME_PROFILE": "  LIVE  "]
        )

        XCTAssertEqual(configuration.runtimeProfile, .live)
    }

    func testInvalidRuntimeProfileFallsBackToLive() {
        let configuration = AppConfiguration(
            infoDictionary: ["APP_RUNTIME_PROFILE": "staging"]
        )

        XCTAssertEqual(configuration.runtimeProfile, .live)
    }

    func testLiveConfigurationUsesBundledBackendURL() throws {
        let bundledBackendURL = try XCTUnwrap(
            Bundle.main.object(forInfoDictionaryKey: "BACKEND_BASE_URL") as? String
        )

        XCTAssertEqual(
            AppConfiguration.live().backendBaseURL.absoluteString,
            bundledBackendURL
        )
    }

    func testInjectedBackendURLIsPreserved() {
        let configuration = AppConfiguration(
            infoDictionary: ["BACKEND_BASE_URL": "  http://localhost:8080  "]
        )

        XCTAssertEqual(configuration.backendBaseURL.absoluteString, "http://localhost:8080")
    }

    func testInvalidBackendURLFallsBackToProduction() {
        let configuration = AppConfiguration(
            infoDictionary: ["BACKEND_BASE_URL": "not a URL"]
        )

        XCTAssertEqual(
            configuration.backendBaseURL.absoluteString,
            "https://re-cap.duckdns.org"
        )
    }

    func testBlankKakaoKeyIsTreatedAsMissingConfiguration() {
        let configuration = AppConfiguration(
            infoDictionary: ["KAKAO_NATIVE_APP_KEY": " \n\t "]
        )

        XCTAssertNil(configuration.kakaoNativeAppKey)
    }

    func testInjectedKakaoKeyIsTrimmedAndPreserved() {
        let configuration = AppConfiguration(
            infoDictionary: ["KAKAO_NATIVE_APP_KEY": "  injected-key  "]
        )

        XCTAssertEqual(configuration.kakaoNativeAppKey, "injected-key")
    }

    func testAppBundleDeclaresKakaoCallbackAndQuerySchemes() throws {
        let info = try XCTUnwrap(Bundle.main.infoDictionary)
        let urlTypes = try XCTUnwrap(info["CFBundleURLTypes"] as? [[String: Any]])
        let callbackSchemes = urlTypes.flatMap {
            $0["CFBundleURLSchemes"] as? [String] ?? []
        }
        let expectedCallback = "kakao" + (AppConfiguration.live().kakaoNativeAppKey ?? "")
        let querySchemes = try XCTUnwrap(info["LSApplicationQueriesSchemes"] as? [String])

        XCTAssertTrue(callbackSchemes.contains(expectedCallback))
        XCTAssertTrue(querySchemes.contains("kakaokompassauth"))
        XCTAssertTrue(querySchemes.contains("kakaolink"))
    }
}

@MainActor
final class RuntimeProfileTests: XCTestCase {
    func testLiveDependenciesPersistCompletedOnboardingWithoutReplacingLiveServices() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "onboarding.progress")
        defer { defaults.removeObject(forKey: "onboarding.progress") }

        let configuration = AppConfiguration.live()
        let firstLaunch = RecapDependencies.live(configuration: configuration)

        XCTAssertEqual(firstLaunch.onboardingProgressStore.progress, .notStarted)
        firstLaunch.onboardingProgressStore.move(to: .completed)

        let nextLaunch = RecapDependencies.live(configuration: configuration)

        XCTAssertEqual(nextLaunch.onboardingProgressStore.progress, .completed)
        XCTAssertEqual(
            AppLaunchDestinationResolver.resolve(
                sessionState: .authenticated(
                    ServerTokenRecord(
                        accessToken: "access",
                        refreshToken: "refresh",
                        accessTokenExpiresAt: .distantFuture
                    )
                ),
                onboardingProgress: nextLaunch.onboardingProgressStore.progress
            ),
            .main
        )
        XCTAssertTrue(nextLaunch.networkClient is AuthenticatedNetworkClient)
        XCTAssertTrue(nextLaunch.homeSummaryLoader is HomeSummaryService)
        XCTAssertTrue(nextLaunch.captureService is CaptureService)
    }

    func testSimulatorMockDependenciesShowOnboardingAfterFirstLogin() async {
        let dependencies = RecapDependencies.simulatorMock()

        XCTAssertEqual(
            AppLaunchDestinationResolver.resolve(
                sessionState: dependencies.sessionStore.state,
                onboardingProgress: dependencies.onboardingProgressStore.progress
            ),
            .login(nil)
        )

        let outcome = await dependencies.sessionStore.login(
            using: dependencies.loginProvider(for: .kakao)
        )

        XCTAssertEqual(outcome, .success)
        XCTAssertEqual(
            AppLaunchDestinationResolver.resolve(
                sessionState: dependencies.sessionStore.state,
                onboardingProgress: dependencies.onboardingProgressStore.progress
            ),
            .onboardingGuide
        )
    }

    func testMockDependenciesStartOnboardingAndAuthenticateWithoutServer() async {
        let dependencies = RecapDependencies.mock()

        XCTAssertEqual(dependencies.sessionStore.state, .signedOut(nil))
        XCTAssertEqual(dependencies.onboardingProgressStore.progress, .notStarted)

        let outcome = await dependencies.sessionStore.login(
            using: dependencies.loginProvider(for: .kakao)
        )

        XCTAssertEqual(outcome, .success)
        guard case .authenticated(let tokenRecord) = dependencies.sessionStore.state else {
            return XCTFail("Mock login should authenticate the session")
        }
        XCTAssertEqual(tokenRecord.accessToken, "mock-access-token")
    }

    func testDefaultMockDependenciesResolveToLogin() {
        let dependencies = RecapDependencies.mock()

        XCTAssertEqual(dependencies.sessionStore.state, .signedOut(nil))
        XCTAssertEqual(dependencies.onboardingProgressStore.progress, .notStarted)
        XCTAssertEqual(
            AppLaunchDestinationResolver.resolve(
                sessionState: dependencies.sessionStore.state,
                onboardingProgress: dependencies.onboardingProgressStore.progress
            ),
            .login(nil)
        )
    }

    func testMockDependenciesSimulateCardCreationProgressWithoutServer() async throws {
        let dependencies = RecapDependencies.mock()
        var progressValues: [Double] = []

        let result = try await dependencies.cardCreationProcessor.process(
            images: [Data([0x01])],
            progress: { update in
                progressValues.append(update.fractionCompleted)
            }
        )

        XCTAssertEqual(result.status, .completed)
        XCTAssertEqual(progressValues.last, 1)
        XCTAssertGreaterThan(progressValues.count, 2)
        XCTAssertEqual(progressValues, progressValues.sorted())
    }

    func testMockFavoriteMutationPersistsAcrossHomeArchiveDetailAndSearch() async throws {
        let dependencies = RecapDependencies.mock()
        let initialHome = try await dependencies.archiveLoader.fetchHome()
        let knowledgeCards = try await dependencies.archiveLoader.fetchCards(
            scope: .category(.knowledge),
            sort: .latest
        )
        let card = try XCTUnwrap(knowledgeCards.first(where: { !$0.isFavorite }))
        let captureID = try XCTUnwrap(card.captureID)

        try await dependencies.captureService.updateFavorite(
            captureID: captureID,
            isFavorite: true
        )

        let refreshedHome = try await dependencies.archiveLoader.fetchHome()
        let refreshedCards = try await dependencies.archiveLoader.fetchCards(
            scope: .category(.knowledge),
            sort: .latest
        )
        let refreshedDetail = try await dependencies.captureService.captureDetail(
            captureID: captureID
        )
        let searchPage = try await dependencies.searchLoader.search(
            query: "파스타",
            scope: .all,
            page: 0,
            size: 20
        )

        XCTAssertEqual(refreshedHome.favoriteCount, initialHome.favoriteCount + 1)
        XCTAssertTrue(
            try XCTUnwrap(refreshedCards.first(where: { $0.captureID == captureID })).isFavorite
        )
        XCTAssertTrue(refreshedDetail.isFavorite)
        XCTAssertTrue(try XCTUnwrap(searchPage.items.first).card.isFavorite)
    }
}
