import AuthenticationServices
import UIKit
import XCTest
@testable import Recap

@MainActor
final class AppleLoginProviderTests: XCTestCase {
    func testProviderIsApple() {
        let provider = AppleLoginProvider(authorizer: AppleAuthorizationAuthorizerSpy())

        XCTAssertEqual(provider.provider, .apple)
    }

    func testProviderRequestsNoScopesAndReturnsUTF8IdentityToken() async throws {
        let authorizer = AppleAuthorizationAuthorizerSpy(
            result: .success(AppleAuthorizationCredential(identityToken: Data("header.payload.signature".utf8)))
        )
        let provider = AppleLoginProvider(authorizer: authorizer)

        let token = try await provider.providerToken()

        XCTAssertEqual(token, "header.payload.signature")
        XCTAssertEqual(authorizer.requestedScopes.count, 1)
        XCTAssertTrue(authorizer.requestedScopes[0].isEmpty)
    }

    func testMissingIdentityTokenThrowsMissingToken() async {
        let provider = AppleLoginProvider(
            authorizer: AppleAuthorizationAuthorizerSpy(
                result: .success(AppleAuthorizationCredential(identityToken: nil))
            )
        )

        await assertProviderToken(provider, throws: .missingToken)
    }

    func testInvalidUTF8IdentityTokenThrowsMissingToken() async {
        let provider = AppleLoginProvider(
            authorizer: AppleAuthorizationAuthorizerSpy(
                result: .success(AppleAuthorizationCredential(identityToken: Data([0xFF])))
            )
        )

        await assertProviderToken(provider, throws: .missingToken)
    }

    func testAuthorizationCanceledNormalizesToCancelled() async {
        let provider = AppleLoginProvider(
            authorizer: AppleAuthorizationAuthorizerSpy(
                result: .failure(authorizationError(.canceled))
            )
        )

        await assertProviderToken(provider, throws: .cancelled)
    }

    func testAuthorizationUnavailableNormalizesToUnavailable() async {
        let provider = AppleLoginProvider(
            authorizer: AppleAuthorizationAuthorizerSpy(
                result: .failure(authorizationError(.notHandled))
            )
        )

        await assertProviderToken(provider, throws: .unavailable)
    }

    func testProviderFailureNormalizesToProviderFailure() async {
        let provider = AppleLoginProvider(
            authorizer: AppleAuthorizationAuthorizerSpy(
                result: .failure(authorizationError(.failed))
            )
        )

        await assertProviderToken(provider, throws: .providerFailure)
    }

    /// 회귀 대상: 연결된 scene이 없을 때 `preconditionFailure`로 크래시하던 문제.
    /// 이제 nil을 돌려주고 호출부가 로그인 실패로 처리한다.
    func testPresentationAnchorIsNilWhenNoWindowSceneExists() {
        XCTAssertNil(ApplePresentationAnchorResolver.anchor(in: []))
    }

    func testOverlappingProviderRequestsAreRejected() async throws {
        let authorizer = SuspendingAppleAuthorizationAuthorizer()
        let provider = AppleLoginProvider(authorizer: authorizer)

        let firstRequest = Task { try await provider.providerToken() }
        while !authorizer.didStart {
            await Task.yield()
        }

        await assertProviderToken(provider, throws: .providerFailure)
        XCTAssertEqual(authorizer.requestedScopes.count, 1)

        authorizer.finish(
            .success(AppleAuthorizationCredential(identityToken: Data("first.jwt".utf8)))
        )
        let token = try await firstRequest.value

        XCTAssertEqual(token, "first.jwt")
    }

    private func assertProviderToken(
        _ provider: AppleLoginProvider,
        throws expectedError: SocialLoginError,
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

    private func authorizationError(_ code: ASAuthorizationError.Code) -> NSError {
        NSError(domain: ASAuthorizationError.errorDomain, code: code.rawValue)
    }
}

@MainActor
private final class AppleAuthorizationAuthorizerSpy: AppleAuthorizationAuthorizing {
    private let result: Result<AppleAuthorizationCredential, any Error>
    private(set) var requestedScopes: [[ASAuthorization.Scope]] = []

    init(result: Result<AppleAuthorizationCredential, any Error> = .failure(SocialLoginError.providerFailure)) {
        self.result = result
    }

    func authorize(scopes: [ASAuthorization.Scope]) async throws -> AppleAuthorizationCredential {
        requestedScopes.append(scopes)
        return try result.get()
    }
}

@MainActor
private final class SuspendingAppleAuthorizationAuthorizer: AppleAuthorizationAuthorizing {
    private(set) var didStart = false
    private(set) var requestedScopes: [[ASAuthorization.Scope]] = []
    private var continuation: CheckedContinuation<AppleAuthorizationCredential, any Error>?

    func authorize(scopes: [ASAuthorization.Scope]) async throws -> AppleAuthorizationCredential {
        requestedScopes.append(scopes)
        didStart = true

        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
        }
    }

    func finish(_ result: Result<AppleAuthorizationCredential, any Error>) {
        guard let continuation else { return }

        self.continuation = nil
        switch result {
        case .success(let credential):
            continuation.resume(returning: credential)
        case .failure(let error):
            continuation.resume(throwing: error)
        }
    }
}
