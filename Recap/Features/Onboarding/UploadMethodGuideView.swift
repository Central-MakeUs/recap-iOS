import SwiftUI

struct UploadMethodGuideView: View {
    private enum CompactLayout {
        static let pageOriginY: CGFloat = 138
        static let primaryActionTopY: CGFloat = 601
        static let imageToActionSpacing: CGFloat = 42

        static let minimumPageHeight = primaryActionTopY - pageOriginY - imageToActionSpacing
    }

    @Environment(\.onboardingVerticalSlack) private var verticalSlack

    private var imageLift: CGFloat {
        min(verticalSlack, 20)
    }

    private var requiresVerticalScroll: Bool {
        verticalSlack > 20
    }

    private var pageContentHeight: CGFloat {
        max(CompactLayout.minimumPageHeight, 512 - verticalSlack)
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            guideText

            if requiresVerticalScroll {
                // 제목과 설명은 고정하고, 남은 공간에서 두 이미지 패널만 스크롤한다.
                // 따라서 CTA와 상단 문구가 서로 겹치지 않는다.
                ScrollView(.vertical) {
                    imagePanels
                }
                .scrollIndicators(.hidden)
                .onboardingFrame(
                    x: 0,
                    y: 198 - imageLift,
                    width: 375,
                    height: pageContentHeight - (198 - imageLift),
                    alignment: .top
                )
            } else {
                imagePanels
                    .onboardingFrame(x: 0, y: 198, width: 375, height: 300, alignment: .top)
            }
        }
        .frame(maxHeight: .infinity, alignment: .top)
    }

    private var guideText: some View {
        ZStack(alignment: .topLeading) {
            Text("필요한 스크린샷만\n골라서 정리할 수 있어요")
                .font(RecapFont.pretendard(size: 22, weight: .semibold))
                .tracking(-0.44)
                .foregroundStyle(Color.recapGray900)
                .onboardingFrame(x: 22, y: 10, width: 245, height: 62, alignment: .leading)

            Text("앨범에서 고르거나 다른 앱에서 공유하면\nRecap이 내용을 읽고 정리해요")
                .font(RecapFont.pretendard(size: 15, weight: .medium))
                .tracking(-0.3)
                .foregroundStyle(Color.recapGray500)
                .onboardingFrame(x: 22, y: 94, width: 260, height: 42, alignment: .leading)
        }
    }

    private var imagePanels: some View {
        VStack(spacing: 42) {
            Image("OnboardingAlbumSelectionPanel")
                .resizable()
                .scaledToFit()
                .frame(width: 331, height: 129)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))

            Image("OnboardingSharePanel")
                .resizable()
                .scaledToFit()
                .frame(width: 331, height: 129)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        }
        .frame(width: 375, height: 300, alignment: .top)
    }
}

#if DEBUG
#Preview("Upload method guide") {
    OnboardingGuideCarouselView(
        initialProgress: .uploadGuide,
        onProgressChanged: { _ in },
        onShowShareSetupTutorial: {},
        onStart: {},
        onSkip: {}
    )
}
#endif
