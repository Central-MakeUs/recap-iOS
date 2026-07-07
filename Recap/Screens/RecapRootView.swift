import SwiftUI

struct RecapRootView: View {
    @State private var phase: AppPhase
    @State private var router: AppRouter
    @State private var cardStore: RecapCardStore
    @State private var selectedRange: InitialRange = .thirtyDays

    init(initialPhase: AppPhase = .onboarding(.introLogin)) {
        self.init(
            initialPhase: initialPhase,
            router: AppRouter(),
            cardStore: RecapCardStore(cards: [])
        )
    }

    init(
        initialPhase: AppPhase = .onboarding(.introLogin),
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
                AppShellView(router: router, cardStore: cardStore)
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
    RecapRootView(
        initialPhase: .main,
        router: AppRouter(),
        cardStore: PreviewStores.recapCardStore()
    )
}
