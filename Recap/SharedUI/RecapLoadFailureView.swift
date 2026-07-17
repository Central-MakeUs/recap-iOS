import SwiftUI

struct RecapLoadFailureView: View {
    enum Style {
        case home
        case archive
    }

    let style: Style
    let retry: () -> Void

    var body: some View {
        switch style {
        case .home:
            homeFailure
        case .archive:
            archiveFailure
        }
    }

    private var homeFailure: some View {
        VStack(spacing: 0) {
            Image("HomeLoadFailureIllustration")
                .resizable()
                .scaledToFit()
                .frame(width: 107, height: 129)

            Text("스크린샷을 불러오지 못했어요")
                .font(RecapFont.pretendard(size: 16, weight: .semibold))
                .tracking(-0.32)
                .foregroundStyle(Color.recapGray300)
                .padding(.top, 19)

            Text("네트워크 상태를 확인 한 뒤\n다시 시도해주세요")
                .font(RecapFont.pretendard(size: 14, weight: .regular))
                .tracking(-0.28)
                .lineSpacing(3)
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.recapGray300)
                .padding(.top, 13)

            Button(action: retry) {
                HStack(spacing: 5) {
                    Image("HomeRetryIcon")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)

                    Text("다시 불러오기")
                        .font(RecapFont.pretendard(size: 14, weight: .semibold))
                        .tracking(-0.28)
                        .foregroundStyle(Color.recapBlue300)
                }
                .frame(width: 155, height: 45)
                .background(Color.recapBlue50)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .buttonStyle(.plain)
            .padding(.top, 23)
        }
        .frame(maxWidth: .infinity)
    }

    private var archiveFailure: some View {
        VStack(spacing: 0) {
            Circle()
                .fill(Color.recapGray100)
                .frame(width: 60, height: 60)
                .overlay {
                    Image(systemName: "exclamationmark")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundStyle(.white)
                }

            Text("스크린샷을 불러오지 못했어요")
                .font(RecapFont.pretendard(size: 16, weight: .semibold))
                .tracking(-0.32)
                .foregroundStyle(Color.recapGray300)
                .padding(.top, 19)

            Text("네트워크 상태를 확인 한 뒤\n다시 시도해주세요")
                .font(RecapFont.pretendard(size: 14, weight: .regular))
                .tracking(-0.28)
                .lineSpacing(1)
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.recapGray300)
                .padding(.top, 9)

            Button(action: retry) {
                HStack(spacing: 5) {
                    Image("HomeRetryIcon")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)

                    Text("다시 불러오기")
                        .font(RecapFont.pretendard(size: 14, weight: .semibold))
                        .tracking(-0.28)
                }
                .foregroundStyle(Color.recapBlue300)
                .frame(width: 155, height: 45)
                .background(Color.recapBlue50)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .buttonStyle(.plain)
            .padding(.top, 23)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview("Home load failure") {
    RecapLoadFailureView(style: .home, retry: {})
}

#Preview("Archive load failure") {
    RecapLoadFailureView(style: .archive, retry: {})
}
