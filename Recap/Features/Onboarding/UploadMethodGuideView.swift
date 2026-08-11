import SwiftUI

struct UploadMethodGuideView: View {
    var body: some View {
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

            Image("OnboardingAlbumSelectionPanel")
                .resizable()
                .scaledToFit()
                .onboardingFrame(x: 22, y: 198, width: 331, height: 129)

            Image("OnboardingSharePanel")
                .resizable()
                .scaledToFit()
                .onboardingFrame(x: 22, y: 363, width: 331, height: 129)
        }
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
