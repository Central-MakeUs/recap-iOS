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
                    .foregroundStyle(Color.settingsTextPrimary)
                    .frame(maxWidth: .infinity)

                HStack {
                    Button(action: leadingAction) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(Color.settingsTextSecondary)
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
                    .foregroundStyle(Color.settingsTextPrimary)

                if let trailingSystemName, let trailingAction {
                    Spacer()

                    Button(action: trailingAction) {
                        Image(systemName: trailingSystemName)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(Color.settingsTextPrimary)
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
                .foregroundStyle(Color.settingsTextTertiary)
                .padding(.leading, 1)

            content
        }
    }
}

struct SettingsAccountSummaryRow: View {
    var body: some View {
        HStack(spacing: 13) {
            SessionAccountIcon()

            Text("로그인됨")
                .font(RecapFont.pretendard(size: 14, weight: .semibold))
                .foregroundStyle(Color.settingsTextPrimary)

            Spacer()
        }
        .frame(height: 65)
        .padding(.horizontal, 15)
    }
}

struct SettingsAccountSummaryCard: View {
    var body: some View {
        HStack(spacing: 13) {
            SessionAccountIcon()

            Text("로그인됨")
                .font(RecapFont.pretendard(size: 15, weight: .semibold))
                .foregroundStyle(Color.settingsTextPrimary)

            Spacer()
        }
        .frame(height: 80)
        .padding(.horizontal, 15)
        .recapCard(radius: 13, borderColor: Color.recapGray100)
    }
}

struct SettingsNavigationRow: View {
    let title: String
    let action: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Text(title)
                .font(SettingsTypography.rowTitle)
                .foregroundStyle(Color.settingsTextPrimary)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.settingsChevron)
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
    var tint: Color = Color.settingsTextPrimary
    var borderColor: Color = Color.recapGray100
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
                    .foregroundStyle(isDestructive ? tint.opacity(0.82) : Color.settingsTextSecondary)
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
                .foregroundStyle(Color.settingsTextSecondary)

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
                    .foregroundStyle(Color.settingsTextPrimary)
                Text(subtitle)
                    .font(RecapFont.pretendard(size: 12, weight: .regular))
                    .foregroundStyle(Color.settingsTextTertiary)
            }

            Spacer()

            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(Color.recapBlue300)
        }
    }
}

struct SessionAccountIcon: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.recapBlue300.opacity(0.12))

            Image(systemName: "person.fill")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.recapBlue300)
        }
        .frame(width: 38, height: 38)
    }
}

struct SettingsDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color.settingsDivider)
            .frame(height: 1)
    }
}
