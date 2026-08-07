import AuthenticationServices
import Foundation
import UIKit

@MainActor
final class AppleLoginProvider: SocialLoginProviding {
    let provider: AuthProvider = .apple

    private let authorizer: any AppleAuthorizationAuthorizing
    private var requestInFlight = false

    init(authorizer: (any AppleAuthorizationAuthorizing)? = nil) {
        self.authorizer = authorizer ?? AppleAuthorizationControllerAuthorizer()
    }

    func providerToken() async throws -> String {
        guard !requestInFlight else {
            throw SocialLoginError.providerFailure
        }

        requestInFlight = true
        defer { requestInFlight = false }

        do {
            try Task.checkCancellation()
            let credential = try await authorizer.authorize(scopes: [])
            try Task.checkCancellation()

            guard
                let identityToken = credential.identityToken,
                let token = String(data: identityToken, encoding: .utf8),
                !token.isEmpty
            else {
                throw SocialLoginError.missingToken
            }

            return token
        } catch {
            throw Self.normalizedError(from: error)
        }
    }

    private static func normalizedError(from error: any Error) -> SocialLoginError {
        if let socialLoginError = error as? SocialLoginError {
            return socialLoginError
        }

        if error is CancellationError {
            return .cancelled
        }

        let authorizationError = error as NSError
        guard
            authorizationError.domain == ASAuthorizationError.errorDomain,
            let code = ASAuthorizationError.Code(rawValue: authorizationError.code)
        else {
            return .providerFailure
        }

        switch code {
        case .canceled:
            return .cancelled
        case .notHandled, .notInteractive:
            return .unavailable
        case .unknown, .invalidResponse, .failed, .matchedExcludedCredential, .credentialImport,
             .credentialExport, .preferSignInWithApple, .deviceNotConfiguredForPasskeyCreation:
            return .providerFailure
        @unknown default:
            return .providerFailure
        }
    }
}

struct AppleAuthorizationCredential: Sendable {
    let identityToken: Data?
}

@MainActor
protocol AppleAuthorizationAuthorizing: AnyObject {
    func authorize(scopes: [ASAuthorization.Scope]) async throws -> AppleAuthorizationCredential
}

/// 로그인 시트를 붙일 창을 고른다.
/// 연결된 scene이 하나도 없으면 nil을 돌려주며, 호출부가 로그인 실패로 처리한다.
@MainActor
enum ApplePresentationAnchorResolver {
    static func anchor(in scenes: [UIWindowScene]) -> ASPresentationAnchor? {
        if let keyWindow = scenes.flatMap(\.windows).first(where: { $0.isKeyWindow }) {
            return keyWindow
        }
        guard let scene = scenes.first else {
            return nil
        }
        return UIWindow(windowScene: scene)
    }
}

@MainActor
private final class AppleAuthorizationControllerAuthorizer: AppleAuthorizationAuthorizing {
    private var session: AppleAuthorizationControllerSession?

    private static func presentationAnchor() -> ASPresentationAnchor? {
        ApplePresentationAnchorResolver.anchor(
            in: UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        )
    }

    func authorize(scopes: [ASAuthorization.Scope]) async throws -> AppleAuthorizationCredential {
        guard session == nil else {
            throw SocialLoginError.providerFailure
        }

        // 로그인 시트를 띄울 창을 먼저 확보한다. 백그라운드 전환 직후처럼 연결된
        // scene이 없으면 컨트롤러를 만들기 전에 실패시켜 로그인 실패로 처리한다.
        guard let anchor = Self.presentationAnchor() else {
            throw SocialLoginError.providerFailure
        }

        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                let request = ASAuthorizationAppleIDProvider().createRequest()
                request.requestedScopes = scopes

                let session = AppleAuthorizationControllerSession(
                    anchor: anchor,
                    continuation: continuation
                ) { [weak self] in
                    self?.session = nil
                }
                let controller = ASAuthorizationController(authorizationRequests: [request])
                controller.delegate = session
                controller.presentationContextProvider = session

                session.controller = controller
                self.session = session

                controller.performRequests()
            }
        } onCancel: {
            Task { @MainActor [weak self] in
                self?.session?.finish(.failure(CancellationError()))
            }
        }
    }
}

@MainActor
private final class AppleAuthorizationControllerSession: NSObject {
    var controller: ASAuthorizationController?

    private let anchor: ASPresentationAnchor
    private var continuation: CheckedContinuation<AppleAuthorizationCredential, any Error>?
    private let onFinish: () -> Void

    init(
        anchor: ASPresentationAnchor,
        continuation: CheckedContinuation<AppleAuthorizationCredential, any Error>,
        onFinish: @escaping () -> Void
    ) {
        self.anchor = anchor
        self.continuation = continuation
        self.onFinish = onFinish
    }

    func finish(_ result: Result<AppleAuthorizationCredential, any Error>) {
        guard let continuation else { return }

        self.continuation = nil
        controller = nil
        onFinish()

        switch result {
        case .success(let credential):
            continuation.resume(returning: credential)
        case .failure(let error):
            continuation.resume(throwing: error)
        }
    }

    deinit {
        continuation?.resume(throwing: CancellationError())
    }
}

extension AppleAuthorizationControllerSession: ASAuthorizationControllerDelegate {
    nonisolated func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        Task { @MainActor in
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                finish(.failure(SocialLoginError.providerFailure))
                return
            }

            finish(.success(AppleAuthorizationCredential(identityToken: credential.identityToken)))
        }
    }

    nonisolated func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: any Error
    ) {
        Task { @MainActor in
            finish(.failure(error))
        }
    }
}

extension AppleAuthorizationControllerSession: ASAuthorizationControllerPresentationContextProviding {
    /// `authorize(scopes:)`에서 미리 확보해 둔 창을 그대로 돌려준다.
    /// 창을 못 구하는 경우는 여기 오기 전에 걸러지므로 실패할 여지가 없다.
    nonisolated func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        if Thread.isMainThread {
            return MainActor.assumeIsolated { anchor }
        }

        return DispatchQueue.main.sync {
            MainActor.assumeIsolated { anchor }
        }
    }
}
