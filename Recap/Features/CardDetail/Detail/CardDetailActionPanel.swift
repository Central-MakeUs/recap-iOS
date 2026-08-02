import SwiftUI

struct CardDetailActionPanel: View {
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onReport: () -> Void
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            actionButton(title: "스크린샷 정보 수정", color: Color.recapGray700, action: onEdit)
            actionButton(title: "스크린샷 삭제", color: Color.recapDestructiveText, action: onDelete)
                .padding(.top, 10)
            actionButton(title: "AI 결과 신고", color: Color.recapGray700, action: onReport)
                .padding(.top, 10)

            Button(action: onClose) {
                Text("닫기")
                    .font(RecapFont.pretendard(size: 15, weight: .medium))
                    .tracking(-0.3)
                    .foregroundStyle(Color.recapGray700)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .contentShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(Color.recapGray100, lineWidth: 1)
                    }
            }
            .buttonStyle(.plain)
                .padding(.top, 24)
        }
        .padding(.top, 35)
        .padding(.horizontal, CardDetailStyle.horizontalPadding)
        .frame(height: 296, alignment: .top)
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
                .background(Color.recapGray50)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

#Preview("정보카드 작업 메뉴") {
    CardDetailActionPanel(onEdit: {}, onDelete: {}, onReport: {}, onClose: {})
}
