import SwiftUI

struct PermissionGuideView: View {
    let onBack: () -> Void
    let onContinue: () -> Void
    let onSkip: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            onboardingHeader(stepText: "1 / 3", onBack: onBack)

            VStack(alignment: .leading, spacing: RecapTheme.Spacing.xLarge) {
                Image(systemName: "photo")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(RecapTheme.ColorToken.primary)
                    .frame(width: 60, height: 60)
                    .background(RecapTheme.ColorToken.primaryLight)
                    .clipShape(RoundedRectangle(cornerRadius: RecapTheme.Radius.large, style: .continuous))

                VStack(alignment: .leading, spacing: RecapTheme.Spacing.medium) {
                    Text("스크린샷을 정리하려면\n사진 접근 권한이 필요해요")
                        .font(.title2.weight(.black))
                        .foregroundStyle(RecapTheme.ColorToken.textPrimary)
                        .lineSpacing(3)

                    Text("RE-CAP은 사용자가 허용한 범위 안에서\n스크린샷만 찾아 정리합니다.")
                        .font(.subheadline)
                        .foregroundStyle(RecapTheme.ColorToken.textSecondary)
                        .lineSpacing(3)
                }

                VStack(alignment: .leading, spacing: RecapTheme.Spacing.large) {
                    PermissionCheckRow(text: "선택한 범위의 스크린샷만 분석해요")
                    PermissionCheckRow(text: "원본 이미지는 앱에서 다시 확인할 수 있어요")
                    PermissionCheckRow(text: "민감한 정보는 확인이 필요한 카드로 분리할 수 있어요")
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, RecapTheme.Spacing.xLarge)
            .padding(.top, RecapTheme.Spacing.xLarge)

            Spacer()

            VStack(spacing: RecapTheme.Spacing.medium) {
                RecapButton(title: "권한 허용하기", style: .primary, action: onContinue)
                Button("나중에 하기", action: onSkip)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(RecapTheme.ColorToken.textTertiary)
            }
            .padding(.horizontal, RecapTheme.Spacing.xLarge)
            .padding(.bottom, RecapTheme.Spacing.xxLarge)
        }
        .background(RecapTheme.ColorToken.background)
    }

    private func onboardingHeader(stepText: String, onBack: @escaping () -> Void) -> some View {
        HStack {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(RecapTheme.ColorToken.textSecondary)
                    .frame(width: 32, height: 32)
                    .background(RecapTheme.ColorToken.surface)
                    .clipShape(RoundedRectangle(cornerRadius: RecapTheme.Radius.small, style: .continuous))
            }
            .buttonStyle(.plain)

            Spacer()

            Text(stepText)
                .font(.footnote.weight(.bold))
                .foregroundStyle(RecapTheme.ColorToken.primary)
        }
        .padding(.horizontal, RecapTheme.Spacing.xLarge)
        .padding(.top, RecapTheme.Spacing.medium)
    }
}

private struct PermissionCheckRow: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: RecapTheme.Spacing.medium) {
            Image(systemName: "checkmark")
                .font(.caption.weight(.black))
                .foregroundStyle(RecapTheme.ColorToken.primary)
                .frame(width: 22, height: 22)
                .background(RecapTheme.ColorToken.primaryLight)
                .clipShape(Circle())

            Text(text)
                .font(.subheadline)
                .foregroundStyle(RecapTheme.ColorToken.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview {
    PermissionGuideView(onBack: {}, onContinue: {}, onSkip: {})
}
