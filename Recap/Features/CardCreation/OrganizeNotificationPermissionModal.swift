import SwiftUI

struct OrganizeNotificationPermissionModal: View {
    let onEnableNotifications: () -> Void
    let onContinueWithoutNotifications: () -> Void

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black.opacity(0.30)
                .ignoresSafeArea()

            permissionSheet
                .transition(.move(edge: .bottom))
        }
        .ignoresSafeArea(edges: .bottom)
    }

    private var permissionSheet: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(Color.recapGray200)
                .frame(width: 43, height: 5)
                .padding(.top, 13)

            Image(systemName: "bell.fill")
                .font(.system(size: 40, weight: .regular))
                .foregroundStyle(Color.recapBlue300)
                .frame(width: 42, height: 41)
                .padding(.top, 25)

            Text("정리가 끝나면 알려드릴까요?")
                .font(RecapFont.pretendard(size: 18, weight: .semibold))
                .tracking(-0.36)
                .foregroundStyle(Color.black)
                .padding(.top, 20)

            Text("앱을 닫아도 스크린샷 정리가 완료되면\n알림을 받고 확인할 수 있어요.")
                .font(RecapFont.pretendard(size: 15, weight: .medium))
                .tracking(-0.30)
                .lineSpacing(0)
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.recapGray500)
                .padding(.top, 12)

            RecapButton(
                title: "알림 받기",
                style: .primary,
                action: onEnableNotifications
            )
            .padding(.horizontal, 16)
            .padding(.top, 35)

            Button(action: onContinueWithoutNotifications) {
                Text("나중에 하기")
                    .font(RecapFont.pretendard(size: 14, weight: .semibold))
                    .tracking(-0.28)
                    .foregroundStyle(Color.recapGray500)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 16)
            .padding(.top, 12)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 351, alignment: .top)
        .background(Color.white)
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: 20,
                topTrailingRadius: 20
            )
        )
        .accessibilityElement(children: .contain)
    }
}

#if DEBUG
#Preview("알림 권한 안내") {
    ZStack {
        Color.recapBackground
            .ignoresSafeArea()

        OrganizeNotificationPermissionModal(
            onEnableNotifications: {},
            onContinueWithoutNotifications: {}
        )
    }
}
#endif
