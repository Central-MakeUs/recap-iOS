import SwiftUI

struct ShareSetupGuideView: View {
    private enum CompactLayout {
        static let speechBubbleY: CGFloat = 214
        static let speechBubbleToHelperSpacing: CGFloat = 53
        static let helperHeight: CGFloat = 43

        static var helperGroupHeight: CGFloat {
            speechBubbleToHelperSpacing + helperHeight
        }
    }

    @Environment(\.onboardingVerticalSlack) private var verticalSlack
    @Environment(\.onboardingCanvasHeight) private var canvasHeight
    @Environment(\.onboardingBottomSafeArea) private var bottomSafeArea

    let onShowTutorial: () -> Void

    private var isSEHeight: Bool {
        verticalSlack >= 100
    }

    private var mockupScale: CGFloat {
        isSEHeight ? 0.9 : 1
    }

    private var mockupHeight: CGFloat {
        238 * mockupScale
    }

    /// SE에서는 말풍선과 안내 링크를 목업 하단의 페이드 영역에 얹는다.
    /// 링크의 하단을 목업 하단과 맞추면, 목업 위·아래 여백을 같은 값으로 유지할 수 있다.
    private var speechBubbleY: CGFloat {
        guard isSEHeight else { return CompactLayout.speechBubbleY }

        // 말풍선·도움말 묶음(96pt)의 절반만 목업 위에 겹친다.
        // 나머지는 목업 아래로 내려 보내면 겹침이 과하지 않으면서
        // 위·아래 여백도 동일한 기준으로 계산할 수 있다.
        return mockupHeight - (CompactLayout.helperGroupHeight / 2)
    }

    private var mockupGroupHeight: CGFloat {
        max(mockupHeight, speechBubbleY + CompactLayout.helperGroupHeight)
    }

    /// 고정된 상단 문구와 하단 버튼 사이의 남은 공간을 목업 위·아래 여백으로
    /// 똑같이 나눈다. 버튼은 carousel의 별도 overlay이므로 여기서 이동하지 않는다.
    private var mockupTopY: CGFloat {
        let pageOriginY: CGFloat = 138
        let subtitleBottomY: CGFloat = 100
        let footerHeight: CGFloat = 112
        let footerBottomPadding: CGFloat = 16
        let primaryActionTopY = canvasHeight - bottomSafeArea - footerBottomPadding - footerHeight
        let contentBottomY = primaryActionTopY - pageOriginY
        let padding = max(20, (contentBottomY - subtitleBottomY - mockupGroupHeight) / 2)

        return subtitleBottomY + padding
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            Text("앨범에서 리캡으로, 더 빠르게 공유하기")
                .font(RecapFont.pretendard(size: 22, weight: .semibold))
                .tracking(-0.44)
                .foregroundStyle(Color.recapGray900)
                .lineLimit(1)
                .onboardingFrame(x: 22, y: 10, width: 331, height: 31, alignment: .leading)

            Text("리캡을 공유 즐겨찾기에 등록해두면\n공유할 때 더보기 버튼을 누르지 않고, 바로 보낼 수 있어요.")
                .font(RecapFont.pretendard(size: 15, weight: .medium))
                .tracking(-0.3)
                .foregroundStyle(Color.recapGray500)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
                .onboardingFrame(x: 22, y: 58, width: 331, height: 42, alignment: .leading)

            // 짧은 화면에서는 목업만 0.9배로 줄이고, 그래도 부족한 높이는
            // 소제목과 목업 사이 여백을 79pt에서 최소 40pt까지 줄인다.
            // 말풍선과 도움말은 목업과 같은 묶음으로 함께 이동한다.
            mockupGroup
                .onboardingFrame(x: 0, y: mockupTopY, width: 375, height: 310, alignment: .top)
        }
    }

    private var mockupGroup: some View {
        ZStack(alignment: .topLeading) {
            ShareSetupMockup()
                .scaleEffect(mockupScale, anchor: .top)
                .onboardingFrame(x: 67, y: 0, width: 239, height: 238)

            RecapSpeechBubble(text: "초간단 30초면 끝나요!")
                .onboardingFrame(x: 117, y: speechBubbleY, width: 143, height: 46)

            Button(action: onShowTutorial) {
                Text("어떻게 등록하나요?")
                    .font(RecapFont.pretendard(size: 15, weight: .medium))
                    .tracking(-0.3)
                    .foregroundStyle(Color.recapGray700)
                    .underline()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .onboardingFrame(
                x: 111,
                y: speechBubbleY + CompactLayout.speechBubbleToHelperSpacing,
                width: 153,
                height: CompactLayout.helperHeight
            )
        }
        .frame(width: 375, height: 310, alignment: .topLeading)
    }
}

struct ShareSetupDetailView: View {
    @State private var page = 0

    let onBack: () -> Void

    var body: some View {
        OnboardingDesignCanvas {
            Button(action: onBack) {
                RecapIconView(icon: .back, size: 24, color: Color.recapGray500)
            }
            .buttonStyle(.plain)
            .onboardingFrame(x: 16, y: 78, width: 24, height: 24)

            Text("공유 즐겨찾기 등록하기")
                .font(RecapFont.pretendard(size: 18, weight: .semibold))
                .tracking(-0.36)
                .foregroundStyle(Color.recapGray900)
                .onboardingFrame(x: 58, y: 77, width: 190, height: 25, alignment: .leading)

            TabView(selection: $page) {
                ForEach(Array(ShareSetupTutorialPage.allCases.enumerated()), id: \.offset) { index, tutorial in
                    ShareSetupTutorialPageView(page: tutorial)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .onboardingFrame(x: 0, y: 174, width: 375, height: 526)

            RecapOnboardingDots(activeIndex: page, count: 4)
                .onboardingFrame(x: 153.5, y: 717, width: 68, height: 8)
        }
    }
}

private enum ShareSetupTutorialPage: String, CaseIterable {
    case openMore = "OnboardingShareTutorial1"
    case openEdit = "OnboardingShareTutorial2"
    case addRecap = "OnboardingShareTutorial3"
    case finish = "OnboardingShareTutorial4"

    var imageSize: CGSize {
        switch self {
        case .openMore:
            CGSize(width: 280.247, height: 374)
        case .openEdit:
            CGSize(width: 294, height: 377)
        case .addRecap, .finish:
            CGSize(width: 282, height: 377)
        }
    }

    var simpleCaption: String? {
        switch self {
        case .openMore:
            "❶ 공유 시트가 열리면 앱 목록을 왼쪽으로 넘겨\n더보기를 눌러주세요"
        case .openEdit:
            "❷ 목록이 열리면 우측 상단 편집 클릭!"
        case .addRecap, .finish:
            nil
        }
    }
}

private struct ShareSetupTutorialPageView: View {
    let page: ShareSetupTutorialPage

    var body: some View {
        VStack(alignment: .leading, spacing: 29) {
            Image(page.rawValue)
                .resizable()
                .interpolation(.high)
                .frame(width: page.imageSize.width, height: page.imageSize.height)

            ShareSetupTutorialCaption(page: page)
        }
        .padding(.top, 23)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

struct FirstCleanupStartView: View {
    var body: some View {
        ZStack(alignment: .topLeading) {
            Text("첫 정리를 시작해볼까요?")
                .font(RecapFont.pretendard(size: 22, weight: .semibold))
                .tracking(-0.44)
                .foregroundStyle(Color.recapGray900)
                .onboardingFrame(x: 22, y: 10, width: 270, height: 31, alignment: .leading)

            Text("쌓아둔 스크린샷을 골라 첫 정리를 시작해보세요!")
                .font(RecapFont.pretendard(size: 15, weight: .medium))
                .tracking(-0.3)
                .foregroundStyle(Color.recapGray500)
                .onboardingFrame(x: 22, y: 58, width: 300, height: 21, alignment: .leading)

            // 폴더 캐릭터는 제자리에 두고 카드 애니메이션만 부족한 높이만큼 올린다.
            // 짧은 화면에서는 카드가 캐릭터 아래로 겹쳐도 CTA를 가리지 않는다.
            Image("OnboardingFirstCleanupIllustration")
                .resizable()
                .frame(width: 375, height: 333)
                .frame(width: 375, height: 170, alignment: .top)
                .clipped()
                .onboardingFrame(x: 0, y: 105, width: 375, height: 170)
                .zIndex(1)

            RecapLottieView(name: "onboarding_final", playback: .loop)
                .onboardingFrame(x: 0, y: 258, width: 375, height: 200)
                .onboardingLiftedOnShortScreen()
                .zIndex(0)
        }
    }
}

private struct ShareSetupMockup: View {
    var body: some View {
        ZStack(alignment: .topLeading) {
            Image("OnboardingShareSetupMockup")
                .resizable()
                .frame(width: 239, height: 238)

            LinearGradient(
                colors: [.white.opacity(0), .white],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(width: 269, height: 90)
            .position(x: 120.5, y: 200)

            Image("OnboardingShareImageIcon")
                .resizable()
                .frame(width: 18, height: 18)
                .position(x: 38, y: 37)

            RecapAppIcon(size: 50, showsName: true)
                .position(x: 36, y: 118)
        }
        .frame(width: 239, height: 238)
    }
}

private struct ShareSetupTutorialCaption: View {
    let page: ShareSetupTutorialPage

    var body: some View {
        Group {
            if let caption = page.simpleCaption {
                Text(caption)
            } else if page == .addRecap {
                HStack(alignment: .center, spacing: 0) {
                    Text("❸ 목록에서 Recap을 찾아, ")
                    Image("OnboardingTutorialGreenPlus")
                        .resizable()
                        .frame(width: 22.627, height: 22.627)
                    Text("를 눌러주세요.")
                }
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Text("❹ 즐겨찾기에 Recap이 추가되면 완료!")
                    HStack(spacing: 4) {
                        Image("OnboardingTutorialMenuIcon")
                            .resizable()
                            .frame(width: 16, height: 16)
                        Text("을 드래그 해 상단으로 끌어올수록,")
                    }
                    Text("즐겨찾기 앞쪽에 배치돼요.")
                }
            }
        }
        .font(RecapFont.pretendard(size: 15, weight: .medium))
        .tracking(-0.3)
        .lineSpacing(4)
        .foregroundStyle(Color.recapGray500)
        .frame(width: 280, alignment: .leading)
    }
}
