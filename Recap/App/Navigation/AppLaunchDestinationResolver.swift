import Foundation

nonisolated enum AppLaunchDestination: Equatable, Sendable {
    case launching
    case login(SessionSignOutReason?)
    case onboardingGuide
    case shareSetupDetail
    case main
}

nonisolated enum AppLaunchDestinationResolver {
    static func resolve(
        sessionState: RecapSessionState,
        onboardingProgress: OnboardingProgress
    ) -> AppLaunchDestination {
        switch sessionState {
        case .launching, .signingOut:
            return .launching
        case .signedOut(let reason):
            return .login(reason)
        case .authenticating:
            return .login(nil)
        case .authenticated:
            return authenticatedDestination(for: onboardingProgress)
        }
    }

    private static func authenticatedDestination(
        for progress: OnboardingProgress
    ) -> AppLaunchDestination {
        switch progress {
        case .notStarted, .loginReady, .permissionGuide, .uploadGuide, .shareSetup,
             .firstCardCreation:
            return .onboardingGuide
        case .shareSetupDetail:
            return .shareSetupDetail
        case .completed:
            return .main
        }
    }
}
