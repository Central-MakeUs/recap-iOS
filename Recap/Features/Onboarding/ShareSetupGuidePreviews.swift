import SwiftUI

#Preview("Share setup guide") {
    ShareSetupGuideView(onShowTutorial: {}, onSkip: {})
}

#Preview("Share setup detail") {
    ShareSetupDetailView(onBack: {})
}

#Preview("First cleanup start") {
    FirstCleanupStartView(onStart: {}, onSkip: {})
}
