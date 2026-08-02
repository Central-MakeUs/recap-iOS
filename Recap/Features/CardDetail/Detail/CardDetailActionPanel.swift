import SwiftUI

struct CardDetailActionPanel: View {
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onReport: () -> Void
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            filledActionButton(
                title: "스크린샷 정보 수정",
                foregroundColor: Color.recapGray700,
                backgroundColor: Color.recapGray50,
                action: onEdit
            )

            filledActionButton(
                title: "스크린샷 삭제",
                foregroundColor: Color.recapDestructiveText,
                backgroundColor: Color.recapDestructiveSoft,
                action: onDelete
            )
            .padding(.top, 8)

            Button(action: onReport) {
                Text("정리 결과 신고")
                    .font(RecapFont.pretendard(size: 14, weight: .regular))
                    .tracking(-0.28)
                    .foregroundStyle(Color.recapGray500)
                    .frame(maxWidth: .infinity)
                    .frame(height: 20)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.top, 27)

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
            .padding(.top, 27)
        }
        .padding(.top, 39)
        .padding(.horizontal, CardDetailStyle.horizontalPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private func filledActionButton(
        title: String,
        foregroundColor: Color,
        backgroundColor: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(title)
                .font(RecapFont.pretendard(size: 16, weight: .semibold))
                .tracking(-0.32)
                .foregroundStyle(foregroundColor)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(backgroundColor)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

#Preview("정보카드 작업 메뉴") {
    CardDetailActionPanel(onEdit: {}, onDelete: {}, onReport: {}, onClose: {})
}
