import SwiftUI

struct CardCreationProcessingView: View {
    let progress: Double
    let notificationsEnabled: Bool
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(height: 157)

            CardCreationProcessingBubble(
                notificationsEnabled: notificationsEnabled
            )

            Image("CardCreationProcessingIllustration")
                .resizable()
                .scaledToFit()
                .frame(width: 179, height: 161)
                .padding(.top, 11)

            CardCreationProgressBar(progress: progress)
                .frame(height: 4)
                .padding(.horizontal, 30)
                .padding(.top, 19)

            Text("스크린샷을 분석 · 정리 하고있어요")
                .font(RecapFont.pretendard(size: 18, weight: .semibold))
                .tracking(-0.36)
                .foregroundStyle(Color.recapGray900)
                .padding(.top, 29)

            Text("정리가 끝나면 바로 알려드릴게요!")
                .font(RecapFont.pretendard(size: 15, weight: .medium))
                .tracking(-0.3)
                .foregroundStyle(Color.recapGray500)
                .padding(.top, 6)

            Spacer(minLength: 20)

            RecapButton(
                title: "정리 취소",
                style: .secondary,
                action: onCancel
            )
            .padding(.horizontal, 16)
            .padding(.bottom, 31)
        }
        .background(Color.recapBackground)
        .ignoresSafeArea(.container, edges: .bottom)
    }
}

private struct CardCreationProcessingBubble: View {
    let notificationsEnabled: Bool

    private enum Layout {
        static let frameSize = CGSize(width: 194.67, height: 67.67)
        static let bodyHeight = frameSize.height * 170 / 203
    }

    var body: some View {
        ZStack(alignment: .top) {
            Image("CardCreationProcessingBubble")
                .resizable()
                .scaledToFit()
                .frame(width: Layout.frameSize.width, height: Layout.frameSize.height)

            Text(message)
                .font(RecapFont.pretendard(size: 13, weight: .medium))
                .tracking(-0.26)
                .lineSpacing(0)
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.recapBlue300)
                .frame(
                    width: Layout.frameSize.width,
                    height: Layout.bodyHeight,
                    alignment: .center
                )
        }
        .frame(width: Layout.frameSize.width, height: Layout.frameSize.height)
    }

    private var message: String {
        if notificationsEnabled {
            "앱을 종료해도 백그라운드에서\n정리가 계속 진행돼요!"
        } else {
            "정리 결과는 앱에서\n확인할 수 있어요!"
        }
    }
}

struct CardCreationProgressBar: View {
    let progress: Double

    private var clampedProgress: Double {
        min(max(progress, 0), 1)
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.recapGray100)

                Capsule()
                    .fill(Color.recapBlue300)
                    .frame(width: proxy.size.width * clampedProgress)
            }
        }
        .accessibilityElement()
        .accessibilityLabel("스크린샷 정리 진행률")
        .accessibilityValue("\(Int(clampedProgress * 100))퍼센트")
        .animation(.linear(duration: 0.25), value: clampedProgress)
    }
}

#Preview("CardCreation progress bar") {
    CardCreationProgressBar(progress: 0.75)
        .frame(width: 315, height: 4)
        .padding()
}

#Preview("CardCreation processing bubble") {
    VStack(spacing: 24) {
        CardCreationProcessingBubble(notificationsEnabled: true)
        CardCreationProcessingBubble(notificationsEnabled: false)
    }
    .padding()
    .background(Color.recapBackground)
}
