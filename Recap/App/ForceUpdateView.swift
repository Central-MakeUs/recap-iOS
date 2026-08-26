import SwiftUI

struct ForceUpdateView: View {
    @Environment(\.openURL) private var openURL

    let status: AppVersionStatus

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            Image(systemName: "arrow.down.app.fill")
                .font(.system(size: 52, weight: .semibold))
                .foregroundStyle(Color.recapBlue300)

            Text("새 버전으로 업데이트해주세요")
                .font(RecapFont.pretendard(size: 22, weight: .semibold))
                .foregroundStyle(Color.recapGray900)
                .padding(.top, 24)

            Text("계속 사용하려면 최신 버전의 Recap이 필요해요.")
                .font(RecapFont.pretendard(size: 15, weight: .regular))
                .foregroundStyle(Color.recapGray500)
                .multilineTextAlignment(.center)
                .padding(.top, 10)

            Spacer()

            RecapButton(title: "업데이트하기", style: .primary) {
                guard let updateURL = status.updateURL else { return }
                openURL(updateURL)
            }
            .disabled(status.updateURL == nil)
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .background(Color.recapBackground)
        .interactiveDismissDisabled()
    }
}

#if DEBUG
#Preview("강제 업데이트") {
    ForceUpdateView(
        status: AppVersionStatus(
            requiresUpdate: true,
            minimumVersion: "1.1.0",
            updateURL: URL(string: "https://apps.apple.com")
        )
    )
}
#endif
