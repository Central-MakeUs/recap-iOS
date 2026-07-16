import SwiftUI

struct PermissionGuideView: View {
    let onContinue: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer(minLength: 118)

            VStack(alignment: .leading, spacing: 12) {
                Text("서비스 이용을 위해\n다음 접근 권한이 필요해요")
                    .font(RecapFont.pretendard(size: 22, weight: .semibold))
                    .tracking(-0.44)
                    .lineSpacing(3)
                    .foregroundStyle(Color.recapGray900)

                Text("권한은 허용 후에도 설정에서 언제든 변경할 수 있어요.")
                    .font(RecapFont.pretendard(size: 15, weight: .medium))
                    .tracking(-0.3)
                    .foregroundStyle(Color.recapGray500)
            }
            .padding(.horizontal, 22)

            VStack(alignment: .leading, spacing: 18) {
                PermissionGuideRow(
                    iconName: "photo.on.rectangle",
                    title: "사진 접근 권한",
                    message: "스크린샷을 불러와 정리하기 위해 필요해요."
                )
                PermissionGuideRow(
                    iconName: "bell.badge",
                    title: "알림 권한",
                    message: "정리가 끝났을 때 알려드리기 위해 사용해요."
                )
                PermissionGuideRow(
                    iconName: "square.and.arrow.up",
                    title: "공유 확장",
                    message: "갤러리나 다른 앱에서 Recap으로 보낼 수 있어요."
                )
            }
            .padding(22)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 185)
            .background(Color.recapControlFill)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .padding(.horizontal, 16)
            .padding(.top, 42)

            Spacer()

            RecapButton(title: "확인했어요", style: .primary, action: onContinue)
                .padding(.horizontal, 16)
                .padding(.bottom, 31)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(Color.recapBackground)
        .toolbar(.hidden, for: .navigationBar)
    }
}

private struct PermissionGuideRow: View {
    let iconName: String
    let title: String
    let message: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: iconName)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color.recapBlue300)
                .frame(width: 36, height: 36)
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(RecapFont.pretendard(size: 15, weight: .semibold))
                    .tracking(-0.3)
                    .foregroundStyle(Color.recapGray900)
                Text(message)
                    .font(RecapFont.pretendard(size: 13, weight: .medium))
                    .tracking(-0.26)
                    .foregroundStyle(Color.recapGray500)
            }
        }
    }
}

#Preview("Permission guide") {
    PermissionGuideView(onContinue: {})
}
