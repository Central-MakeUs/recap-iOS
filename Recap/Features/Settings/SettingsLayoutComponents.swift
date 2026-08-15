import SwiftUI

struct SettingsNavigationHeader: View {
    let title: String
    let dismiss: () -> Void

    var body: some View {
        HStack(spacing: 13) {
            Button(action: dismiss) {
                RecapIconView(icon: .back, size: 24, color: Color.recapGray900)
                    .frame(width: 24, height: 24)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("뒤로")

            Text(title)
                .font(SettingsTypography.navigationTitle)
                .foregroundStyle(Color.recapGray900)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, SettingsLayout.navigationHorizontalPadding)
        .padding(.top, SettingsLayout.navigationTopPadding)
        .frame(height: SettingsLayout.navigationHeight + SettingsLayout.navigationTopPadding)
    }
}

struct SettingsListSection<Rows: View>: View {
    let title: String
    let isFirst: Bool
    @ViewBuilder let rows: Rows

    init(
        title: String,
        isFirst: Bool = false,
        @ViewBuilder rows: () -> Rows
    ) {
        self.title = title
        self.isFirst = isFirst
        self.rows = rows()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(SettingsTypography.sectionTitle)
                .foregroundStyle(Color.recapGray500)
                .frame(height: 20)

            Spacer()
                .frame(height: SettingsLayout.sectionTitleToRows)

            rows
        }
        .padding(.horizontal, SettingsLayout.horizontalPadding)
        .padding(.top, isFirst ? SettingsLayout.firstSectionTopPadding : SettingsLayout.sectionTopPadding)
        .padding(.bottom, SettingsLayout.sectionBottomPadding)
    }
}

struct SettingsNavigationRow: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 0) {
                Text(title)
                    .font(SettingsTypography.rowTitle)
                    .foregroundStyle(Color.recapGray900)

                Spacer(minLength: 0)

                RecapIconView(icon: .forward, size: 16, color: Color.recapGray300)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .clipped()
    }
}

struct SettingsSectionDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color.recapGray50)
            .frame(height: SettingsLayout.dividerHeight)
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(Color.recapGray100)
                    .frame(height: 1)
            }
    }
}

#Preview("설정 공통 레이아웃") {
    VStack(spacing: 0) {
        SettingsNavigationHeader(title: "설정", dismiss: {})
        SettingsListSection(title: "계정", isFirst: true) {
            SettingsNavigationRow(title: "계정 관리", action: {})
        }
        SettingsSectionDivider()
        Spacer()
    }
    .background(Color.recapBackground)
}
