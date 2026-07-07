import SwiftUI

struct RecapRootView: View {
    @State private var phase: AppPhase
    @State private var selectedRange: InitialRange = .thirtyDays
    @State private var selectedTab: MainTab = .home

    init(initialPhase: AppPhase = .onboarding(.introLogin)) {
        _phase = State(initialValue: initialPhase)
    }

    var body: some View {
        Group {
            switch phase {
            case .onboarding(let step):
                onboardingView(for: step)
                    .transition(.opacity.combined(with: .move(edge: .trailing)))
            case .main:
                MainTabShellView(selectedTab: $selectedTab)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.22), value: phase)
    }

    @ViewBuilder
    private func onboardingView(for step: OnboardingStep) -> some View {
        switch step {
        case .introLogin:
            OnboardingIntroView(
                onStart: { phase = .onboarding(.permissionGuide) }
            )
        case .permissionGuide:
            PermissionGuideView(
                onBack: { phase = .onboarding(.introLogin) },
                onContinue: { phase = .onboarding(.rangeSelection) },
                onSkip: { phase = .onboarding(.rangeSelection) }
            )
        case .rangeSelection:
            InitialRangeSelectionView(
                selectedRange: $selectedRange,
                onBack: { phase = .onboarding(.permissionGuide) },
                onContinue: { phase = .main }
            )
        }
    }
}

#Preview("Onboarding start") {
    RecapRootView()
}

#Preview("Main tabs") {
    RecapRootView(initialPhase: .main)
}
