import SwiftUI

struct RecapRootView: View {
    @State private var sessionStore: RecapSessionStore
    @State private var onboardingStore: OnboardingProgressStore
    @State private var router: AppRouter
    @State private var cardStore: CardStore
    @State private var isSplashPresented: Bool
    @State private var requiredUpdateStatus: AppVersionStatus?

    private let dependencies: RecapDependencies

    init(
        dependencies: RecapDependencies,
        initiallyShowsSplash: Bool = true
    ) {
        self.init(
            dependencies: dependencies,
            router: AppRouter(),
            cardStore: CardStore(
                captureMutator: dependencies.captureService,
                invalidationCenter: dependencies.cardDataInvalidationCenter
            ),
            initiallyShowsSplash: initiallyShowsSplash
        )
    }

    init(
        dependencies: RecapDependencies,
        router: AppRouter,
        cardStore: CardStore,
        initiallyShowsSplash: Bool = true
    ) {
        self.dependencies = dependencies
        _sessionStore = State(initialValue: dependencies.sessionStore)
        _onboardingStore = State(initialValue: dependencies.onboardingProgressStore)
        _router = State(initialValue: router)
        _cardStore = State(initialValue: cardStore)
        _isSplashPresented = State(initialValue: initiallyShowsSplash)
        _requiredUpdateStatus = State(initialValue: nil)
    }

    private var destination: AppLaunchDestination {
        AppLaunchDestinationResolver.resolve(
            sessionState: sessionStore.state,
            onboardingProgress: onboardingStore.progress
        )
    }

    var body: some View {
        Group {
            if isSplashPresented {
                AppSplashView(onFinished: finishSplash)
            } else {
                destinationView
            }
        }
        .animation(.easeInOut(duration: 0.22), value: destination)
        .task {
            if sessionStore.state == .launching {
                await sessionStore.restore()
            }
        }
        .task {
            guard let status = try? await dependencies.appVersionService.checkCurrentVersion(),
                  status.requiresUpdate
            else {
                return
            }
            requiredUpdateStatus = status
        }
        .task(id: sessionStore.state) {
            await sessionStore.refreshAccessTokenWhenNeeded()
        }
        .fullScreenCover(item: $requiredUpdateStatus) { status in
            ForceUpdateView(status: status)
        }
    }

    @ViewBuilder
    private var destinationView: some View {
        switch destination {
        case .launching:
            ProgressView()
        case .login:
            loginView
        case .onboardingGuide:
            OnboardingGuideCarouselView(
                initialProgress: onboardingStore.progress,
                onProgressChanged: onboardingStore.move,
                onShowShareSetupTutorial: {
                    onboardingStore.move(to: .shareSetupDetail)
                },
                onStart: completeOnboardingAndStartCardCreation,
                onSkip: completeOnboarding
            )
        case .shareSetupDetail:
            ShareSetupDetailView(
                onBack: { onboardingStore.move(to: .shareSetup) }
            )
        case .main:
            AppShellView(
                router: router,
                cardStore: cardStore,
                homeSummaryLoader: dependencies.homeSummaryLoader,
                archiveLoader: dependencies.archiveLoader,
                searchLoader: dependencies.searchLoader,
                captureService: dependencies.captureService,
                userAccountService: dependencies.userAccountService,
                cardCreationProcessor: dependencies.cardCreationProcessor,
                cardDataInvalidationCenter: dependencies.cardDataInvalidationCenter,
                organizeNotificationStore: dependencies.organizeNotificationStore,
                aiDataTransferConsentStore: dependencies.aiDataTransferConsentStore,
                onLogout: logout,
                onAccountWithdrawalCompleted: completeAccountWithdrawal
            )
        }
    }

    private func finishSplash() {
        if onboardingStore.progress == .notStarted {
            onboardingStore.move(to: .loginReady)
        }
        isSplashPresented = false
    }

    private var loginView: some View {
        OnboardingLoginView(
            onStart: onboardingStore.startAfterLoginIfNeeded,
            login: { provider in
                let authProvider: AuthProvider = provider == .kakao ? .kakao : .apple
                return await sessionStore.login(
                    using: dependencies.loginProvider(for: authProvider)
                )
            }
        )
    }

    private func completeOnboarding() {
        onboardingStore.move(to: .completed)
    }

    private func completeOnboardingAndStartCardCreation() {
        onboardingStore.move(to: .completed)
        router.navigate(.cardCreationStart)
    }

    private func logout() {
        Task {
            let outcome = await sessionStore.logout()
            if outcome == .success {
                MainTab.allCases.forEach(router.reset)
            }
        }
    }

    private func completeAccountWithdrawal() {
        sessionStore.completeAccountWithdrawal()
        MainTab.allCases.forEach(router.reset)
    }
}

#if DEBUG
#Preview("Onboarding start") {
    RecapRootView(
        dependencies: .preview(
            sessionState: .signedOut(nil),
            onboardingProgress: .notStarted
        )
    )
}

#Preview("Main tabs") {
    RecapRootView(
        dependencies: .preview(
            sessionState: .authenticated(
                ServerTokenRecord(
                    accessToken: "preview-access",
                    refreshToken: "preview-refresh",
                    accessTokenExpiresAt: .distantFuture
                )
            ),
            onboardingProgress: .completed
        ),
        router: AppRouter(),
        cardStore: PreviewStores.cardStore(),
        initiallyShowsSplash: false
    )
}

#Preview("Session expired login") {
    RecapRootView(
        dependencies: .preview(
            sessionState: .signedOut(.sessionExpired),
            onboardingProgress: .completed
        ),
        initiallyShowsSplash: false
    )
}

#Preview("Login in progress") {
    RecapRootView(
        dependencies: .preview(
            sessionState: .authenticating(.kakao),
            onboardingProgress: .loginReady
        ),
        initiallyShowsSplash: false
    )
}
#endif
