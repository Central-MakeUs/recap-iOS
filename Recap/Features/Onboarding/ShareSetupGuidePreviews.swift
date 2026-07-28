import SwiftUI

#Preview("Share setup guide") {
    OnboardingGuideCarouselView(
        initialProgress: .shareSetup,
        onProgressChanged: { _ in },
        onShowShareSetupTutorial: {},
        onStart: {},
        onSkip: {}
    )
}

#Preview("Share setup detail") {
    ShareSetupDetailView(onBack: {})
}

#Preview("First cleanup start") {
    OnboardingGuideCarouselView(
        initialProgress: .firstCardCreation,
        onProgressChanged: { _ in },
        onShowShareSetupTutorial: {},
        onStart: {},
        onSkip: {}
    )
}
