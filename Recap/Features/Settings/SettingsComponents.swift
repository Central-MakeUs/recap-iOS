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
            .frame(height: SettingsLayout.rowHeight)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .frame(height: SettingsLayout.rowHeight)
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

struct SettingsNotificationPermissionBanner: View {
    let enableNotifications: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Image("SettingsNotificationDisabled")
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)

            Text("기기 알림이 꺼져있어요")
                .font(SettingsTypography.noticeTitle)
                .foregroundStyle(Color.recapGray900)

            Spacer(minLength: 0)

            Button(action: enableNotifications) {
                HStack(spacing: 2) {
                    Text("켜기")
                        .font(SettingsTypography.rowStatus)
                    RecapIconView(icon: .forward, size: 16, color: Color.recapBlue300)
                }
                .foregroundStyle(Color.recapBlue300)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .frame(height: 56)
        .background(Color.recapGray50, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

struct SettingsNotificationRow: View {
    let isEnabled: Bool
    let toggle: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("정리 알림")
                    .font(RecapFont.pretendard(size: 16, weight: .semibold))
                    .foregroundStyle(Color.recapGray900)

                Text("스크린샷 정리가 완료되거나 실패했을 때\n알려드려요.")
                    .font(SettingsTypography.body)
                    .foregroundStyle(Color.recapGray500)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)

            SettingsSwitch(
                isOn: isEnabled,
                action: toggle
            )
            .padding(.top, 2)
        }
    }
}

struct SettingsSwitch: View {
    let isOn: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Capsule()
                .fill(isOn ? Color.recapBlue300 : Color.recapGray200)
                .frame(width: 47, height: 25)
                .overlay(alignment: isOn ? .trailing : .leading) {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 21, height: 21)
                        .padding(2)
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("정리 알림")
        .accessibilityValue(isOn ? "켬" : "끔")
    }
}

struct SettingsAccountProviderRow: View {
    let providerName: String
    let joinedDateText: String
    let showsKakaoIcon: Bool

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
        if showsKakaoIcon {
            Image("SettingsKakaoIcon")
                .resizable()
                .scaledToFit()
                .frame(width: 30, height: 30)
        } else {
            Circle()
                .fill(Color.recapBlue50)
                .frame(width: 30, height: 30)
                .overlay {
                    RecapIconView(icon: .information, size: 16, color: Color.recapBlue300)
                }
        }
    }
}

struct SettingsUnavailableView: View {
    @Environment(\.dismiss) private var dismiss
    let title: String

    var body: some View {
        VStack(spacing: 0) {
            SettingsNavigationHeader(title: title, dismiss: { dismiss() })

            RecapIncompleteCallout(
                title: "\(title) 미구현",
                message: "Figma에 확정된 연결 화면이나 서버 계약이 없어 아직 제공하지 않아요."
            )
            .padding(.horizontal, SettingsLayout.horizontalPadding)
            .padding(.top, 32)

            Spacer()
        }
        .background(Color.recapBackground)
        .toolbar(.hidden, for: .navigationBar)
    }
}

#Preview("설정 목록 행") {
    SettingsNavigationRow(title: "계정 관리", action: {})
        .padding(.horizontal, SettingsLayout.horizontalPadding)
}

#Preview("알림 권한 배너") {
    SettingsNotificationPermissionBanner(enableNotifications: {})
        .padding()
}

#Preview("설정 미구현 화면") {
    SettingsUnavailableView(title: "문의하기")
}
