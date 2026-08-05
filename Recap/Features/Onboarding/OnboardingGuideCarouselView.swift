import SwiftUI

struct OnboardingGuideCarouselView: View {
    enum Page: Int, CaseIterable, Identifiable {
        case uploadMethod
        case shareSetup
        case firstCardCreation

        var id: Self { self }

        init(progress: OnboardingProgress) {
            switch progress {
            case .shareSetup, .shareSetupDetail:
                self = .shareSetup
            case .firstCardCreation:
                self = .firstCardCreation
            case .notStarted, .loginReady, .permissionGuide, .uploadGuide, .completed:
                self = .uploadMethod
            }
        }

        var progress: OnboardingProgress {
            switch self {
            case .uploadMethod:
                .uploadGuide
            case .shareSetup:
                .shareSetup
            case .firstCardCreation:
                .firstCardCreation
            }
        }
    }

    @State private var page: Page?

    let onProgressChanged: (OnboardingProgress) -> Void
    let onShowShareSetupTutorial: () -> Void
    let onStart: () -> Void
    let onSkip: () -> Void

    init(
        initialProgress: OnboardingProgress,
        onProgressChanged: @escaping (OnboardingProgress) -> Void,
        onShowShareSetupTutorial: @escaping () -> Void,
        onStart: @escaping () -> Void,
        onSkip: @escaping () -> Void
    ) {
        _page = State(initialValue: Page(progress: initialProgress))
        self.onProgressChanged = onProgressChanged
        self.onShowShareSetupTutorial = onShowShareSetupTutorial
        self.onStart = onStart
        self.onSkip = onSkip
    }

    var body: some View {
        OnboardingDesignCanvas {
            RecapOnboardingDots(activeIndex: selectedPage.rawValue, count: Page.allCases.count)
                .onboardingFrame(x: 162, y: 74, width: 51, height: 8)

            RecapLogoText(size: 20.73)
                .onboardingFrame(x: 22, y: 112, width: 65, height: 26, alignment: .leading)

            pageContent
                .onboardingFrame(x: 0, y: 138, width: 375, height: 512)

            footer
        }
        .onChange(of: page) { _, newPage in
            guard let newPage else { return }
            onProgressChanged(newPage.progress)
        }
    }

    private var selectedPage: Page {
        page ?? .uploadMethod
    }

    private var pageContent: some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: 0) {
                UploadMethodGuideView()
                    .containerRelativeFrame(.horizontal)
                    .id(Page.uploadMethod)

                ShareSetupGuideView(onShowTutorial: onShowShareSetupTutorial)
                    .containerRelativeFrame(.horizontal)
                    .id(Page.shareSetup)

                FirstCleanupStartView()
                    .containerRelativeFrame(.horizontal)
                    .id(Page.firstCardCreation)
            }
            .scrollTargetLayout()
        }
        .scrollIndicators(.hidden)
        .scrollTargetBehavior(.paging)
        .scrollPosition(id: $page)
    }

    @ViewBuilder
    private var footer: some View {
        switch selectedPage {
        case .uploadMethod:
            RecapButton(
                title: "확인했어요",
                style: .primary,
                action: { move(to: .shareSetup) }
            )
            .onboardingFrame(x: 16, y: 729, width: 343, height: 50)

        case .shareSetup:
            ShareLink(item: "Recap") {
                Text("공유시트 열기")
                    .font(RecapFont.pretendard(size: 14, weight: .semibold))
                    .tracking(-0.28)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .buttonStyle(RecapButtonStyle(style: .primary, size: .large))
            .onboardingFrame(x: 16, y: 679, width: 343, height: 50)

            secondaryButton(title: "나중에 하기") {
                move(to: .firstCardCreation)
            }

        case .firstCardCreation:
            RecapButton(
                title: "스크린샷 선택하기",
                style: .primary,
                action: onStart
            )
            .onboardingFrame(x: 16, y: 679, width: 343, height: 50)

            secondaryButton(title: "나중에 하기", action: onSkip)
        }
    }

    private func secondaryButton(
        title: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(title)
                .font(RecapFont.pretendard(size: 14, weight: .semibold))
                .tracking(-0.28)
                .foregroundStyle(Color.recapGray500)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onboardingFrame(x: 16, y: 741, width: 343, height: 50)
    }

    private func move(to page: Page) {
        withAnimation(.smooth(duration: 0.3)) {
            self.page = page
        }
    }
}

#Preview("온보딩 안내 캐러셀") {
    OnboardingGuideCarouselView(
        initialProgress: .uploadGuide,
        onProgressChanged: { _ in },
        onShowShareSetupTutorial: {},
        onStart: {},
        onSkip: {}
    )
}
