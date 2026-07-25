import Foundation

nonisolated enum AppLaunchDestination: Equatable, Sendable {
    case launching
    case serviceIntro
    case login(SessionSignOutReason?)
    case uploadGuide
    case shareSetup
    case shareSetupDetail
    case firstCardCreation
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
            return onboardingProgress == .notStarted ? .serviceIntro : .login(reason)
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
        case .notStarted, .loginReady, .permissionGuide:
            return .uploadGuide
        case .uploadGuide:
            return .uploadGuide
        case .shareSetup:
            return .shareSetup
        case .shareSetupDetail:
            return .shareSetupDetail
        case .firstCardCreation:
            return .firstCardCreation
        case .completed:
            return .main
        }
    }
}
