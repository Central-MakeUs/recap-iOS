import SwiftUI

struct SettingsHeader: View {
    let title: String
    var leadingAction: (() -> Void)?
    var trailingSystemName: String?
    var trailingAction: (() -> Void)?

    var body: some View {
        if let leadingAction {
            ZStack {
                Text(title)
                    .font(RecapFont.pretendard(size: 17, weight: .semibold))
                    .foregroundStyle(SettingsColor.textPrimary)
                    .frame(maxWidth: .infinity)

                HStack {
                    Button(action: leadingAction) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(SettingsColor.textSecondary)
                            .frame(width: 24, height: 24)
                    }
                    .buttonStyle(.plain)

                    Spacer()
                }
            }
            .frame(height: 32)
        } else {
            HStack {
                Text(title)
                    .font(RecapFont.pretendard(size: 22, weight: .bold))
                    .foregroundStyle(SettingsColor.textPrimary)

                if let trailingSystemName, let trailingAction {
                    Spacer()

                    Button(action: trailingAction) {
                        Image(systemName: trailingSystemName)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(SettingsColor.textPrimary)
                            .frame(width: 24, height: 24)
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(height: 32)
        }
    }
}

struct SettingsSection<Content: View>: View {
    let title: String
    let content: Content

    init(
        title: String,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title)
                .font(SettingsTypography.sectionTitle)
                .foregroundStyle(SettingsColor.textTertiary)
                .padding(.leading, 1)

            content
        }
    }
}

struct SettingsAccountSummaryRow: View {
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 13) {
            KakaoAccountIcon()

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(RecapFont.pretendard(size: 14, weight: .semibold))
                    .foregroundStyle(SettingsColor.textPrimary)
                Text(subtitle)
                    .font(SettingsTypography.rowCaption)
                    .foregroundStyle(SettingsColor.textTertiary)
            }

            Spacer()
        }
        .frame(height: 65)
        .padding(.horizontal, 15)
    }
}

struct SettingsAccountSummaryCard: View {
    var body: some View {
        HStack(spacing: 13) {
            KakaoAccountIcon()

            VStack(alignment: .leading, spacing: 3) {
                Text("Recap 사용자")
                    .font(RecapFont.pretendard(size: 15, weight: .semibold))
                    .foregroundStyle(SettingsColor.textPrimary)
                Text("카카오로 로그인 중")
                    .font(SettingsTypography.rowCaption)
                    .foregroundStyle(SettingsColor.textSecondary)
                Text("recap_user@kakao.com")
                    .font(SettingsTypography.rowCaption)
                    .foregroundStyle(SettingsColor.textTertiary)
            }

            Spacer()
        }
        .frame(height: 80)
        .padding(.horizontal, 15)
        .recapCard(radius: 13, borderColor: SettingsColor.cardBorder)
    }
}

struct SettingsNavigationRow: View {
    let title: String
    let action: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Text(title)
                .font(SettingsTypography.rowTitle)
                .foregroundStyle(SettingsColor.textPrimary)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(SettingsColor.chevron)
        }
        .frame(height: 43)
        .padding(.horizontal, 15)
        .contentShape(Rectangle())
        .onTapGesture(perform: action)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
    }
}

struct SettingsActionCard: View {
    let title: String
    let message: String
    var tint: Color = SettingsColor.textPrimary
    var borderColor: Color = SettingsColor.cardBorder
    var isDestructive = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(SettingsTypography.rowTitle)
                    .foregroundStyle(tint)
                Text(message)
                    .font(SettingsTypography.rowCaption)
                    .foregroundStyle(isDestructive ? tint.opacity(0.82) : SettingsColor.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 67)
            .padding(.horizontal, 15)
            .recapCard(radius: 13, borderColor: borderColor)
        }
        .buttonStyle(.plain)
    }
}

struct SettingsToggleSection<Content: View>: View {
    let title: String
    let content: Content

    init(
        title: String,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 26) {
            Text(title)
                .font(RecapFont.pretendard(size: 13, weight: .regular))
                .foregroundStyle(SettingsColor.textSecondary)

            VStack(spacing: 26) {
                content
            }
        }
    }
}

struct SettingsToggleRow: View {
    let title: String
    let subtitle: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 10) {
                Text(title)
                    .font(RecapFont.pretendard(size: 15, weight: .semibold))
                    .foregroundStyle(SettingsColor.textPrimary)
                Text(subtitle)
                    .font(RecapFont.pretendard(size: 12, weight: .regular))
                    .foregroundStyle(SettingsColor.textTertiary)
            }

            Spacer()

            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(RecapTheme.ColorToken.primary)
        }
    }
}

struct KakaoAccountIcon: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(Color(red: 1, green: 222 / 255, blue: 0))

            Image(systemName: "message.fill")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(Color(red: 24 / 255, green: 24 / 255, blue: 24 / 255))
        }
        .frame(width: 38, height: 38)
    }
}

struct SettingsDivider: View {
    var body: some View {
        Rectangle()
            .fill(SettingsColor.divider)
            .frame(height: 1)
    }
}

