import SwiftUI

struct SettingsAccountProviderRow: View {
    let providerName: String
    let joinedDateText: String
    let provider: AuthProvider?

    var body: some View {
        HStack(spacing: 13) {
            providerIcon

            VStack(alignment: .leading, spacing: 4) {
                Text(providerName)
                    .font(SettingsTypography.rowTitle)
                    .foregroundStyle(Color.recapGray900)

                Text(joinedDateText)
                    .font(SettingsTypography.body)
                    .foregroundStyle(Color.recapGray500)
            }

            Spacer(minLength: 0)
        }
        .frame(height: 72)
    }

    @ViewBuilder
    private var providerIcon: some View {
        switch provider {
        case .kakao:
            Image("SettingsKakaoIcon")
                .resizable()
                .scaledToFit()
                .frame(width: 30, height: 30)
        case .apple:
            Image("OnboardingAppleLoginButton")
                .resizable()
                .scaledToFit()
                .frame(width: 30, height: 30)
        case nil:
            Circle()
                .fill(Color.recapGray100)
                .frame(width: 30, height: 30)
        }
    }
}

#Preview("로그인 정보") {
    VStack(spacing: 0) {
        SettingsAccountProviderRow(
            providerName: "Apple로 로그인",
            joinedDateText: "2026년 8월 4일 가입",
            provider: .apple
        )
        SettingsAccountProviderRow(
            providerName: "카카오로 로그인",
            joinedDateText: "2026년 8월 4일 가입",
            provider: .kakao
        )
    }
    .padding(.horizontal, SettingsLayout.horizontalPadding)
    .background(Color.recapBackground)
}
