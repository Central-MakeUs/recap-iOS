import Foundation
import KakaoSDKAuth
import KakaoSDKCommon
import KakaoSDKUser

@MainActor
final class KakaoLoginProvider: SocialLoginProviding {
    let provider: AuthProvider = .kakao

    private let client: KakaoLoginClient

    convenience init() {
        self.init(client: .live)
    }

    init(client: KakaoLoginClient) {
        self.client = client
    }

    func providerToken() async throws -> String {
        do {
            try Task.checkCancellation()

            let token: String?
            if client.isKakaoTalkLoginAvailable() {
                token = try await client.loginWithKakaoTalk()
            } else {
                token = try await client.loginWithKakaoAccount()
            }

            try Task.checkCancellation()

            guard let token = token?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !token.isEmpty else {
                throw SocialLoginError.missingToken
            }

            return token
        } catch is CancellationError {
            throw CancellationError()
        } catch let error as SocialLoginError {
            throw error
        } catch {
            throw client.socialLoginError(error) ?? .providerFailure
        }
    }
}

@MainActor
struct KakaoLoginClient {
    var isKakaoTalkLoginAvailable: () -> Bool
    var loginWithKakaoTalk: () async throws -> String?
    var loginWithKakaoAccount: () async throws -> String?
    var socialLoginError: (Error) -> SocialLoginError?

    init(
        isKakaoTalkLoginAvailable: @escaping () -> Bool,
        loginWithKakaoTalk: @escaping () async throws -> String?,
        loginWithKakaoAccount: @escaping () async throws -> String?,
        socialLoginError: @escaping (Error) -> SocialLoginError?
    ) {
        self.isKakaoTalkLoginAvailable = isKakaoTalkLoginAvailable
        self.loginWithKakaoTalk = loginWithKakaoTalk
        self.loginWithKakaoAccount = loginWithKakaoAccount
        self.socialLoginError = socialLoginError
    }
}

extension KakaoLoginClient {
    static let live = KakaoLoginClient(
        isKakaoTalkLoginAvailable: {
            UserApi.isKakaoTalkLoginAvailable()
        },
        loginWithKakaoTalk: {
            try await UserApi.shared.recapLoginWithKakaoTalkAccessToken()
        },
        loginWithKakaoAccount: {
            try await UserApi.shared.recapLoginWithKakaoAccountAccessToken()
        },
        socialLoginError: { error in
            guard let sdkError = error as? SdkError else {
                return nil
            }

            switch sdkError {
            case .ClientFailed(let reason, _):
                switch reason {
                case .Cancelled:
                    return .cancelled
                case .MustInitAppKey, .NotSupported:
                    return .unavailable
                default:
                    return .providerFailure
                }
            default:
                return .providerFailure
            }
        }
    )
}

private extension UserApi {
    func recapLoginWithKakaoTalkAccessToken() async throws -> String? {
        try await withCheckedThrowingContinuation { continuation in
            loginWithKakaoTalk { oauthToken, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                continuation.resume(returning: oauthToken?.accessToken)
            }
        }
    }

    func recapLoginWithKakaoAccountAccessToken() async throws -> String? {
        try await withCheckedThrowingContinuation { continuation in
            loginWithKakaoAccount { oauthToken, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                continuation.resume(returning: oauthToken?.accessToken)
            }
        }
    }
}
