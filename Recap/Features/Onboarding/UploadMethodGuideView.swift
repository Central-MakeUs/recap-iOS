import SwiftUI

struct UploadMethodGuideView: View {
    let onContinue: () -> Void

    var body: some View {
        OnboardingDesignCanvas {
            RecapOnboardingDots(activeIndex: 0, count: 3)
                .onboardingFrame(x: 162, y: 74, width: 51, height: 8)

            RecapLogoText(size: 20.73)
                .onboardingFrame(x: 22, y: 112, width: 65, height: 26, alignment: .leading)

            Text("필요한 스크린샷만\n골라서 정리할 수 있어요")
                .font(RecapFont.pretendard(size: 22, weight: .semibold))
                .tracking(-0.44)
                .foregroundStyle(Color.recapGray900)
                .onboardingFrame(x: 22, y: 148, width: 245, height: 62, alignment: .leading)

            Text("앨범에서 고르거나 다른 앱에서 공유하면\nRecap이 내용을 읽고 정리해요")
                .font(RecapFont.pretendard(size: 15, weight: .medium))
                .tracking(-0.3)
                .foregroundStyle(Color.recapGray500)
                .onboardingFrame(x: 22, y: 232, width: 260, height: 42, alignment: .leading)

            Image("OnboardingAlbumSelectionPanel")
                .resizable()
                .scaledToFit()
                .onboardingFrame(x: 22, y: 336, width: 331, height: 129)

            Image("OnboardingSharePanel")
                .resizable()
                .scaledToFit()
                .onboardingFrame(x: 22, y: 501, width: 331, height: 129)

            RecapButton(title: "확인했어요", style: .primary, action: onContinue)
                .onboardingFrame(x: 16, y: 729, width: 343, height: 50)
        }
    }
}

#Preview("Upload method guide") {
    UploadMethodGuideView(onContinue: {})
}
