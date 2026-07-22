import Foundation

@MainActor
protocol SocialLoginProviding: AnyObject {
    var provider: AuthProvider { get }

    func providerToken() async throws -> String
}

nonisolated enum SocialLoginError: Error, Equatable, Sendable {
    case cancelled
    case unavailable
    case providerFailure
    case missingToken
}
