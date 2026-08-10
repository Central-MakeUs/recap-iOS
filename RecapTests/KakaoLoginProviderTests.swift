import XCTest
@testable import Recap

@MainActor
final class KakaoLoginProviderTests: XCTestCase {
    /// 회귀 대상: SDK 미초기화 상태에서 로그인하면 SDK 내부 `try!`가 앱을 죽이던 문제.
    /// 이제 호출 전에 걸러 `unavailable`로 넘긴다.
    func testUninitializedSDKThrowsUnavailableWithoutCallingSDK() async {
        let provider = KakaoLoginProvider(
            client: KakaoLoginClient(
                isSDKInitialized: { false },
                isKakaoTalkLoginAvailable: {
                    XCTFail("SDK 미초기화 시 SDK를 호출하면 안 된다")
                    return true
                },
                loginWithKakaoTalk: {
                    XCTFail("SDK 미초기화 시 SDK를 호출하면 안 된다")
                    return "talk-access-token"
                },
                loginWithKakaoAccount: {
                    XCTFail("SDK 미초기화 시 SDK를 호출하면 안 된다")
                    return "account-access-token"
                },
                socialLoginError: { _ in nil }
            )
        )

        do {
            _ = try await provider.providerToken()
            XCTFail("unavailable이 전달되어야 한다")
        } catch {
            XCTAssertEqual(error as? SocialLoginError, .unavailable)
        }
    }

    func testProviderUsesKakaoTalkWhenAvailable() async throws {
        let provider = KakaoLoginProvider(
            client: KakaoLoginClient(
                isKakaoTalkLoginAvailable: { true },
                loginWithKakaoTalk: { "talk-access-token" },
                loginWithKakaoAccount: {
                    XCTFail("KakaoAccount fallback should not be used")
                    return "account-access-token"
                },
                socialLoginError: { _ in nil }
            )
        )

        let token = try await provider.providerToken()

        XCTAssertEqual(provider.provider, .kakao)
        XCTAssertEqual(token, "talk-access-token")
    }

    func testProviderFallsBackToKakaoAccountWhenTalkIsUnavailable() async throws {
        let provider = KakaoLoginProvider(
            client: KakaoLoginClient(
                isKakaoTalkLoginAvailable: { false },
                loginWithKakaoTalk: {
                    XCTFail("KakaoTalk login should not be used")
                    return "talk-access-token"
                },
                loginWithKakaoAccount: { "account-access-token" },
                socialLoginError: { _ in nil }
            )
        )

        let token = try await provider.providerToken()

        XCTAssertEqual(token, "account-access-token")
    }

    func testProviderTreatsBlankSDKTokenAsMissingToken() async {
        let provider = KakaoLoginProvider(
            client: KakaoLoginClient(
                isKakaoTalkLoginAvailable: { true },
                loginWithKakaoTalk: { "   " },
                loginWithKakaoAccount: { "account-access-token" },
                socialLoginError: { _ in nil }
            )
        )

        do {
            _ = try await provider.providerToken()
            XCTFail("Expected missing token")
        } catch let error as SocialLoginError {
            XCTAssertEqual(error, .missingToken)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testProviderNormalizesSDKUserCancel() async {
        let provider = KakaoLoginProvider(
            client: KakaoLoginClient(
                isKakaoTalkLoginAvailable: { true },
                loginWithKakaoTalk: { throw KakaoLoginProviderTestError.cancelled },
                loginWithKakaoAccount: { "account-access-token" },
                socialLoginError: { error in
                    error as? KakaoLoginProviderTestError == .cancelled ? .cancelled : nil
                }
            )
        )

        do {
            _ = try await provider.providerToken()
            XCTFail("Expected cancellation")
        } catch let error as SocialLoginError {
            XCTAssertEqual(error, .cancelled)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testProviderMapsUnavailableSeparatelyFromGenericFailure() async {
        let unavailableProvider = KakaoLoginProvider(
            client: KakaoLoginClient(
                isKakaoTalkLoginAvailable: { true },
                loginWithKakaoTalk: { throw KakaoLoginProviderTestError.unavailable },
                loginWithKakaoAccount: { "account-access-token" },
                socialLoginError: { error in
                    error as? KakaoLoginProviderTestError == .unavailable ? .unavailable : nil
                }
            )
        )
        let genericFailureProvider = KakaoLoginProvider(
            client: KakaoLoginClient(
                isKakaoTalkLoginAvailable: { true },
                loginWithKakaoTalk: { throw KakaoLoginProviderTestError.generic },
                loginWithKakaoAccount: { "account-access-token" },
                socialLoginError: { _ in nil }
            )
        )

        await assertSocialLoginError(.unavailable, from: unavailableProvider)
        await assertSocialLoginError(.providerFailure, from: genericFailureProvider)
    }

    func testBootstrapSkipsMissingOrBlankAppKey() {
        XCTAssertFalse(KakaoSDKBootstrap.initialize(appKey: nil))
        XCTAssertFalse(KakaoSDKBootstrap.initialize(appKey: " \n\t "))
    }

    private func assertSocialLoginError(
        _ expectedError: SocialLoginError,
        from provider: KakaoLoginProvider,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        do {
            _ = try await provider.providerToken()
            XCTFail("Expected \(expectedError)", file: file, line: line)
        } catch let error as SocialLoginError {
            XCTAssertEqual(error, expectedError, file: file, line: line)
        } catch {
            XCTFail("Unexpected error: \(error)", file: file, line: line)
        }
    }
}

private enum KakaoLoginProviderTestError: Error {
    case cancelled
    case unavailable
    case generic
}
