import SwiftUI

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

            SettingsSwitch(isOn: isEnabled, action: toggle)
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

#if DEBUG
#Preview("알림 설정 컴포넌트") {
    VStack(spacing: 24) {
        SettingsNotificationPermissionBanner(enableNotifications: {})
        SettingsNotificationRow(isEnabled: true, toggle: {})
        SettingsNotificationRow(isEnabled: false, toggle: {})
    }
    .padding(SettingsLayout.horizontalPadding)
    .background(Color.recapBackground)
}
#endif
