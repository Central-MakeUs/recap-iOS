import SwiftUI

struct RecapRootView: View {
    @State private var sessionStore: RecapSessionStore
    @State private var onboardingStore: OnboardingProgressStore
    @State private var router: AppRouter
    @State private var cardStore: RecapCardStore

    private let dependencies: RecapDependencies

    init(dependencies: RecapDependencies) {
        self.init(
            dependencies: dependencies,
            router: AppRouter(),
            cardStore: RecapCardStore(cards: SampleData.cards)
        )
    }

    init(
        dependencies: RecapDependencies,
        router: AppRouter,
        cardStore: RecapCardStore
    ) {
        self.dependencies = dependencies
        _sessionStore = State(initialValue: dependencies.sessionStore)
        _onboardingStore = State(initialValue: dependencies.onboardingProgressStore)
        _router = State(initialValue: router)
        _cardStore = State(initialValue: cardStore)
    }

    private var destination: AppLaunchDestination {
        AppLaunchDestinationResolver.resolve(
            sessionState: sessionStore.state,
            onboardingProgress: onboardingStore.progress
        )
    }

    var body: some View {
        Group {
            switch destination {
            case .launching:
                ProgressView()
            case .serviceIntro:
                OnboardingIntroView {
                    onboardingStore.move(to: .loginReady)
                }
            case .login(let reason):
                loginView(signOutReason: reason)
            case .permissionGuide:
                PermissionGuideView {
                    onboardingStore.move(to: .shareSetup)
                }
            case .shareSetup:
                ShareSetupGuideView(
                    onNext: { onboardingStore.move(to: .shareSetupDetail) },
                    onSkip: { onboardingStore.move(to: .firstCardCreation) }
                )
            case .shareSetupDetail:
                ShareSetupDetailView(
                    onBack: { onboardingStore.move(to: .shareSetup) },
                    onNext: { onboardingStore.move(to: .firstCardCreation) }
                )
            case .firstCardCreation:
                FirstCleanupStartView(
                    onStart: completeOnboarding,
                    onSkip: completeOnboarding
                )
            case .main:
                AppShellView(
                    router: router,
                    cardStore: cardStore,
                    homeSummaryLoader: dependencies.homeSummaryLoader,
                    onLogout: logout
                )
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

    private func loginView(signOutReason: SessionSignOutReason?) -> some View {
        OnboardingLoginView(
            notice: loginNotice(for: signOutReason),
            onStart: { onboardingStore.move(to: .permissionGuide) },
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
            return "로그인 세션이 만료됐어요. 다시 로그인해주세요."
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

    private func logout() {
        Task {
            let outcome = await sessionStore.logout()
            if outcome == .success {
                MainTab.allCases.forEach(router.reset)
            }
        }
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
        cardStore: PreviewStores.recapCardStore()
    )
}

#Preview("Session expired login") {
    RecapRootView(
        dependencies: .preview(
            sessionState: .signedOut(.sessionExpired),
            onboardingProgress: .completed
        )
    )
}

#Preview("Login in progress") {
    RecapRootView(
        dependencies: .preview(
            sessionState: .authenticating(.kakao),
            onboardingProgress: .loginReady
        )
    )
}
