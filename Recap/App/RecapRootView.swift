import SwiftUI

struct RecapRootView: View {
    @State private var phase: AppPhase
    @State private var router: AppRouter
    @State private var cardStore: RecapCardStore

    init(initialPhase: AppPhase = .main) {
        self.init(
            initialPhase: initialPhase,
            router: AppRouter(),
            cardStore: RecapCardStore(cards: SampleData.cards)
        )
    }

    init(
        initialPhase: AppPhase = .main,
        router: AppRouter,
        cardStore: RecapCardStore
    ) {
        _phase = State(initialValue: initialPhase)
        _router = State(initialValue: router)
        _cardStore = State(initialValue: cardStore)
    }

    var body: some View {
        Group {
            switch phase {
            case .onboarding(let step):
                onboardingView(for: step)
                    .transition(.opacity.combined(with: .move(edge: .trailing)))
            case .main:
                AppShellView(
                    router: router,
                    cardStore: cardStore,
                    onLogout: {
                        MainTab.allCases.forEach(router.reset)
                        phase = .onboarding(.login)
                    }
                )
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.22), value: phase)
    }

    @ViewBuilder
    private func onboardingView(for step: OnboardingStep) -> some View {
        switch step {
        case .serviceIntro:
            OnboardingIntroView(
                onStart: { phase = .onboarding(.login) }
            )
        case .login:
            OnboardingLoginView(
                onStart: { phase = .onboarding(.permissionGuide) }
            )
        case .permissionGuide:
            PermissionGuideView(
                onContinue: { phase = .onboarding(.shareSetup) }
            )
        case .shareSetup:
            ShareSetupGuideView(
                onNext: { phase = .onboarding(.shareSetupDetail) },
                onSkip: { phase = .onboarding(.firstCleanup) }
            )
        case .shareSetupDetail:
            ShareSetupDetailView(
                onBack: { phase = .onboarding(.shareSetup) },
                onNext: { phase = .onboarding(.firstCleanup) }
            )
        case .firstCleanup:
            FirstCleanupStartView(
                onStart: { phase = .main },
                onSkip: { phase = .main }
            )
        }
    }
}

#Preview("Onboarding start") {
    RecapRootView(initialPhase: .onboarding(.serviceIntro))
}

#Preview("Main tabs") {
    RecapRootView(
        initialPhase: .main,
        router: AppRouter(),
        cardStore: PreviewStores.recapCardStore()
    )
}
