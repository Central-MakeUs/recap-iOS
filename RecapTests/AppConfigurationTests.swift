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
final class MockRuntimeProfileTests: XCTestCase {
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
}
