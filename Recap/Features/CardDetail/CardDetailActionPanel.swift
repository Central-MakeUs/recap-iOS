import SwiftUI

struct CardDetailActionPanel: View {
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            actionButton(title: "스크린샷 정보 수정", color: RecapTheme.ColorToken.textBody, action: onEdit)
            actionButton(title: "스크린샷 삭제", color: CardDetailStyle.destructiveText, action: onDelete)
                .padding(.top, 10)

            Button("닫기", action: onClose)
                .font(RecapFont.pretendard(size: 15, weight: .medium))
                .tracking(-0.3)
                .foregroundStyle(RecapTheme.ColorToken.textBody)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .overlay {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(RecapTheme.ColorToken.border, lineWidth: 1)
                }
                .buttonStyle(.plain)
                .padding(.top, 24)
        }
        .padding(.top, 35)
        .padding(.horizontal, CardDetailStyle.horizontalPadding)
        .frame(height: 236, alignment: .top)
        .background(Color.white)
    }

    private func actionButton(title: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(RecapFont.pretendard(size: 16, weight: .semibold))
                .tracking(-0.32)
                .foregroundStyle(color)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color(red: 243 / 255, green: 245 / 255, blue: 249 / 255))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

#Preview("정보카드 작업 메뉴") {
    CardDetailActionPanel(onEdit: {}, onDelete: {}, onClose: {})
}
