import SwiftUI

struct ShareOrganizingView: View {
    let progress: Double
    let notificationsEnabled: Bool
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(height: 157)

            processingBubble

            Image("CardCreationProcessingIllustration")
                .resizable()
                .scaledToFit()
                .frame(width: 179, height: 161)
                .padding(.top, 11)

            progressBar
                .frame(width: 315, height: 4)
                .padding(.top, 19)

            Text("스크린샷을 분석 · 정리 하고있어요")
                .font(.custom("Pretendard-SemiBold", size: 18))
                .tracking(-0.36)
                .foregroundStyle(Color("RecapGray900"))
                .padding(.top, 29)

            Text("정리가 끝나면 바로 알려드릴게요!")
                .font(.custom("Pretendard-Medium", size: 15))
                .tracking(-0.3)
                .foregroundStyle(Color("RecapGray500"))
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
        .background(Color("RecapBackground"))
        .ignoresSafeArea(.container, edges: .bottom)
    }

    private var processingBubble: some View {
        ZStack(alignment: .top) {
            Image("CardCreationProcessingBubble")
                .resizable()
                .scaledToFit()
                .frame(width: 194.67, height: 67.67)

            Text(bubbleMessage)
                .font(.custom("Pretendard-Medium", size: 13))
                .tracking(-0.26)
                .multilineTextAlignment(.center)
                .foregroundStyle(Color("RecapBlue300"))
                .frame(width: 194.67, height: 56.67)
        }
        .frame(width: 194.67, height: 67.67)
    }

    private var bubbleMessage: String {
        if notificationsEnabled {
            "앱을 종료해도 백그라운드에서\n정리가 계속 진행돼요!"
        } else {
            "정리 결과는 앱에서\n확인할 수 있어요!"
        }
    }

    private var progressBar: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color("RecapGray100"))

                Capsule()
                    .fill(Color("RecapBlue300"))
                    .frame(width: proxy.size.width * clampedProgress)
            }
        }
        .animation(.linear(duration: 0.25), value: clampedProgress)
        .accessibilityElement()
        .accessibilityLabel("스크린샷 정리 진행률")
        .accessibilityValue("\(Int(clampedProgress * 100))퍼센트")
    }

    private var clampedProgress: Double {
        min(max(progress, 0), 1)
    }
}

struct ShareOrganizeCompleteView: View {
    let organizedCount: Int
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(height: 141)

            Image("CardCreationSuccessIcon")
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: 40)

            Text("\(organizedCount)개의 스크린샷을\n정리했어요")
                .font(.custom("Pretendard-SemiBold", size: 18))
                .tracking(-0.36)
                .multilineTextAlignment(.center)
                .foregroundStyle(Color("RecapGray900"))
                .padding(.top, 10)

            Image("CardCreationCompleteIllustration")
                .resizable()
                .scaledToFit()
                .frame(width: 195.09, height: 177.43)
                .padding(.top, 25)

            Text("보관함에서 확인해보세요!")
                .font(.custom("Pretendard-Medium", size: 15))
                .tracking(-0.3)
                .foregroundStyle(Color("RecapGray500"))
                .padding(.top, 21)

            Spacer(minLength: 20)

            RecapButton(
                title: "완료",
                action: onDone
            )
            .padding(.horizontal, 16)
            .padding(.bottom, 31)
        }
        .background(Color("RecapBackground"))
        .ignoresSafeArea(.container, edges: .bottom)
    }
}

struct ShareOrganizeFailureView: View {
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(height: 141)

            Image("CardCreationFailureIcon")
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: 40)

            Text("스크린샷을 정리하지 못했어요")
                .font(.custom("Pretendard-SemiBold", size: 18))
                .tracking(-0.36)
                .foregroundStyle(Color("RecapGray900"))
                .padding(.top, 10)

            Image("CardCreationFailureIllustration")
                .resizable()
                .scaledToFit()
                .frame(width: 123, height: 95)
                .padding(.top, 56)

            Text("다음에 다시 시도해주세요.")
                .font(.custom("Pretendard-Medium", size: 15))
                .tracking(-0.3)
                .foregroundStyle(Color("RecapGray500"))
                .padding(.top, 22)

            Spacer(minLength: 20)

            RecapButton(
                title: "닫기",
                action: onClose
            )
            .padding(.horizontal, 16)
            .padding(.bottom, 31)
        }
        .background(Color("RecapBackground"))
        .ignoresSafeArea(.container, edges: .bottom)
    }
}

#Preview("04-02_공유 정리 시작") {
    ShareOrganizingView(progress: 0.75, notificationsEnabled: false, onCancel: {})
}

#Preview("04-03_공유 정리 완료") {
    ShareOrganizeCompleteView(organizedCount: 5, onDone: {})
}

#Preview("04-04_공유 정리 실패") {
    ShareOrganizeFailureView(onClose: {})
}
