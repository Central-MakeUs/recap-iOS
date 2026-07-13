import XCTest
@testable import Recap

@MainActor
final class KakaoLoginProviderTests: XCTestCase {
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
