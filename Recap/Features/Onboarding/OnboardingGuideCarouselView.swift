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
            OnboardingGuideCarouselContent(
                page: $page,
                onShowShareSetupTutorial: onShowShareSetupTutorial
            )
        }
        .overlay(alignment: .bottom) {
            footer
                .padding(.horizontal, 16)
                .safeAreaPadding(.bottom, 16)
                // 세로 스크롤 콘텐츠가 CTA 위로 합성되지 않도록 항상 최상단에 둔다.
                .zIndex(1)
        }
        .onChange(of: page) { _, newPage in
            guard let newPage else { return }
            onProgressChanged(newPage.progress)
        }
    }

    private var selectedPage: Page {
        page ?? .uploadMethod
    }

    @ViewBuilder
    private var footer: some View {
        VStack(spacing: 12) {
            switch selectedPage {
            case .uploadMethod:
                RecapButton(
                    title: "확인했어요",
                    style: .primary,
                    action: { move(to: .shareSetup) }
                )
                .frame(height: 50)

            case .shareSetup:
                ShareLink(item: "Recap") {
                    Text("공유시트 열기")
                        .font(RecapFont.pretendard(size: 14, weight: .semibold))
                        .tracking(-0.28)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .buttonStyle(RecapButtonStyle(style: .primary, size: .large))
                .frame(height: 50)

                secondaryButton(title: "나중에 하기") {
                    move(to: .firstCardCreation)
                }

            case .firstCardCreation:
                RecapButton(
                    title: "스크린샷 선택하기",
                    style: .primary,
                    action: onStart
                )
                .frame(height: 50)

                secondaryButton(title: "나중에 하기", action: onSkip)
            }
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
        .frame(height: 50)
    }

    private func move(to page: Page) {
        withAnimation(.smooth(duration: 0.3)) {
            self.page = page
        }
    }
}

private struct OnboardingGuideCarouselContent: View {
    private enum CompactLayout {
        static let pageOriginY: CGFloat = 138
        static let primaryActionTopY: CGFloat = 601
        static let imageToActionSpacing: CGFloat = 42

        static let minimumPageHeight = primaryActionTopY - pageOriginY - imageToActionSpacing
    }

    @Environment(\.onboardingVerticalSlack) private var verticalSlack

    @Binding var page: OnboardingGuideCarouselView.Page?

    let onShowShareSetupTutorial: () -> Void

    private var selectedPage: OnboardingGuideCarouselView.Page {
        page ?? .uploadMethod
    }

    private var pageContentHeight: CGFloat {
        max(320, 512 - verticalSlack)
    }

    /// 짧은 화면에서 두 번째 페이지의 말풍선이 잘리지 않도록, 이 페이지에는
    /// 말풍선까지 표시할 수 있는 최소 세로 영역을 남긴다. 동시에 첫 페이지의
    /// 마지막 이미지와 고정 CTA 사이에는 최소 42pt를 남긴다.
    private var carouselViewportHeight: CGFloat {
        max(CompactLayout.minimumPageHeight, pageContentHeight)
    }

    var body: some View {
        RecapOnboardingDots(
            activeIndex: selectedPage.rawValue,
            count: OnboardingGuideCarouselView.Page.allCases.count
        )
        .onboardingFrame(x: 162, y: 74, width: 51, height: 8)

        RecapLogoText(size: 20.73)
            .onboardingFrame(x: 22, y: 112, width: 65, height: 26, alignment: .leading)

        ScrollView(.horizontal) {
            LazyHStack(spacing: 0) {
                UploadMethodGuideView()
                    .containerRelativeFrame(.horizontal)
                    .frame(maxHeight: .infinity, alignment: .top)
                    .id(OnboardingGuideCarouselView.Page.uploadMethod)

                ShareSetupGuideView(onShowTutorial: onShowShareSetupTutorial)
                    .containerRelativeFrame(.horizontal)
                    .frame(maxHeight: .infinity, alignment: .top)
                    .id(OnboardingGuideCarouselView.Page.shareSetup)

                FirstCleanupStartView()
                    .containerRelativeFrame(.horizontal)
                    .frame(maxHeight: .infinity, alignment: .top)
                    .id(OnboardingGuideCarouselView.Page.firstCardCreation)
            }
            .scrollTargetLayout()
        }
        .scrollIndicators(.hidden)
        .scrollTargetBehavior(.paging)
        .scrollPosition(id: $page)
        .onboardingFrame(x: 0, y: 138, width: 375, height: carouselViewportHeight)
    }
}

#if DEBUG
#Preview("온보딩 안내 캐러셀") {
    OnboardingGuideCarouselView(
        initialProgress: .uploadGuide,
        onProgressChanged: { _ in },
        onShowShareSetupTutorial: {},
        onStart: {},
        onSkip: {}
    )
}
#endif
