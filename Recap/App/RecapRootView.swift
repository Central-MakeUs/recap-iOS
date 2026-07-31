import SwiftUI

struct RecapRootView: View {
    @State private var sessionStore: RecapSessionStore
    @State private var onboardingStore: OnboardingProgressStore
    @State private var router: AppRouter
    @State private var cardStore: RecapCardStore
    @State private var isSplashPresented: Bool

    private let dependencies: RecapDependencies

    init(
        dependencies: RecapDependencies,
        initiallyShowsSplash: Bool = true
    ) {
        self.init(
            dependencies: dependencies,
            router: AppRouter(),
            cardStore: RecapCardStore(cards: SampleData.cards),
            initiallyShowsSplash: initiallyShowsSplash
        )
    }

    init(
        dependencies: RecapDependencies,
        router: AppRouter,
        cardStore: RecapCardStore,
        initiallyShowsSplash: Bool = true
    ) {
        self.dependencies = dependencies
        _sessionStore = State(initialValue: dependencies.sessionStore)
        _onboardingStore = State(initialValue: dependencies.onboardingProgressStore)
        _router = State(initialValue: router)
        _cardStore = State(initialValue: cardStore)
        _isSplashPresented = State(initialValue: initiallyShowsSplash)
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
        .task(id: sessionStore.state) {
            await sessionStore.refreshAccessTokenWhenNeeded()
        }
    }

    @ViewBuilder
    private var destinationView: some View {
        switch destination {
        case .launching:
            ProgressView()
        case .login(let reason):
            loginView(signOutReason: reason)
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
                organizeNotificationController: dependencies.organizeNotificationController,
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

    private func loginView(signOutReason: SessionSignOutReason?) -> some View {
        OnboardingLoginView(
            notice: loginNotice(for: signOutReason),
            onStart: onboardingStore.startAfterLoginIfNeeded,
            login: { provider in
                let authProvider: AuthProvider = provider == .kakao ? .kakao : .apple
                return await sessionStore.login(
                    using: dependencies.loginProvider(for: authProvider)
                )
            }
        )
    }

    private func loginNotice(for reason: SessionSignOutReason?) -> String? {
        switch reason {
        case .sessionExpired:
            // 세션 만료는 사용자가 한 일이 아니므로 별도 안내 없이 로그인 화면만 보여준다.
            return nil
        case .sessionRefreshFailed:
            return "로그인 세션을 갱신하지 못했어요. 네트워크를 확인해주세요."
        case .secureStorageFailed:
            return "로그인 정보를 불러오지 못했어요. 다시 로그인해주세요."
        case .authenticationFailed, nil:
            return nil
        }
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
        cardStore: PreviewStores.recapCardStore(),
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
