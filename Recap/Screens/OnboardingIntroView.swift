import SwiftUI

struct OnboardingIntroView: View {
    let onStart: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: RecapTheme.Spacing.xLarge)

            RecapLogo(showsSubtitle: true)
                .padding(.bottom, RecapTheme.Spacing.large)

            onboardingArtwork
                .padding(.horizontal, RecapTheme.Spacing.large)
                .padding(.bottom, RecapTheme.Spacing.xLarge)

            VStack(alignment: .leading, spacing: RecapTheme.Spacing.medium) {
                Text("저장된 스크린샷을\n필요한 순간 다시 찾을 수 있게")
                    .font(.title2.weight(.black))
                    .foregroundStyle(RecapTheme.ColorToken.textPrimary)
                    .lineSpacing(3)

                Text("맛집, 상품, 일정, 레퍼런스까지\n스크린샷 속 정보를 카드와 컬렉션으로 정리해요.")
                    .font(.subheadline)
                    .foregroundStyle(RecapTheme.ColorToken.textSecondary)
                    .lineSpacing(3)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, RecapTheme.Spacing.xLarge)

            Spacer(minLength: RecapTheme.Spacing.xLarge)

            VStack(spacing: RecapTheme.Spacing.medium) {
                RecapButton(title: "카카오로 시작하기", systemImage: "message.fill", style: .kakao, action: onStart)
                RecapButton(title: "Apple로 시작하기", systemImage: "apple.logo", style: .dark, action: onStart)

                Button("이메일로 로그인", action: onStart)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(RecapTheme.ColorToken.textTertiary)
                    .padding(.top, RecapTheme.Spacing.small)
            }
            .padding(.horizontal, RecapTheme.Spacing.xLarge)
            .padding(.bottom, RecapTheme.Spacing.xxLarge)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(RecapTheme.ColorToken.background)
    }

    private var onboardingArtwork: some View {
        ZStack {
            RoundedRectangle(cornerRadius: RecapTheme.Radius.xLarge, style: .continuous)
                .fill(RecapTheme.ColorToken.primarySoft)
                .frame(height: 160)

            RoundedRectangle(cornerRadius: RecapTheme.Radius.medium, style: .continuous)
                .fill(.white)
                .frame(width: 116, height: 140)
                .rotationEffect(.degrees(-8))
                .shadow(color: RecapTheme.ColorToken.primary.opacity(0.10), radius: 18, y: 10)
                .overlay(alignment: .top) {
                    VStack(spacing: 10) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(RecapTheme.ColorToken.thumbnail)
                            .frame(width: 70, height: 34)
                        RoundedRectangle(cornerRadius: 3)
                            .fill(RecapTheme.ColorToken.border)
                            .frame(width: 72, height: 8)
                        RoundedRectangle(cornerRadius: 3)
                            .fill(RecapTheme.ColorToken.border)
                            .frame(width: 58, height: 8)
                    }
                    .padding(.top, 18)
                }

            RoundedRectangle(cornerRadius: RecapTheme.Radius.medium, style: .continuous)
                .fill(.white)
                .frame(width: 124, height: 82)
                .offset(x: 44, y: -4)
                .shadow(color: RecapTheme.ColorToken.primary.opacity(0.12), radius: 18, y: 12)
                .overlay(alignment: .leading) {
                    VStack(alignment: .leading, spacing: 5) {
                        HStack(spacing: 5) {
                            Circle()
                                .fill(RecapTheme.ColorToken.primary)
                                .frame(width: 7, height: 7)
                            Text("다시 볼 정보")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(RecapTheme.ColorToken.primary)
                        }
                        Text("성수동 브런치\n맛집")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(RecapTheme.ColorToken.textPrimary)
                    }
                    .padding(.leading, 14)
                }

            Image(systemName: "chevron.right")
                .font(.headline.weight(.black))
                .foregroundStyle(.white)
                .frame(width: 42, height: 42)
                .background(RecapTheme.ColorToken.primary)
                .clipShape(Circle())
                .shadow(color: RecapTheme.ColorToken.primary.opacity(0.30), radius: 12, y: 8)
                .offset(y: 30)
        }
    }
}

#Preview {
    OnboardingIntroView(onStart: {})
}
