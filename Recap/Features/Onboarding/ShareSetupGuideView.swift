import SwiftUI

struct ShareSetupGuideView: View {
    let onShowTutorial: () -> Void

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

            ShareSetupMockup()
                .onboardingFrame(x: 67, y: 179, width: 239, height: 238)

            RecapSpeechBubble(text: "초간단 30초면 끝나요!")
                .onboardingFrame(x: 117, y: 393, width: 143, height: 46)

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
                .onboardingFrame(x: 111, y: 446, width: 153, height: 43)
        }
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

            // 정적 일러스트는 상단 폴더 캐릭터만 남기고, 카드 줄은 애니메이션으로 대체한다.
            Image("OnboardingFirstCleanupIllustration")
                .resizable()
                .frame(width: 375, height: 333)
                .frame(width: 375, height: 170, alignment: .top)
                .clipped()
                .onboardingFrame(x: 0, y: 105, width: 375, height: 170)

            RecapLottieView(name: "onboarding_final", playback: .loop)
                .onboardingFrame(x: 0, y: 258, width: 375, height: 200)
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
