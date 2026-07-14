import SwiftUI

struct CardConfirmationDialog: View {
    let title: String
    let message: String
    let cancelTitle: String
    let confirmTitle: String
    let onCancel: () -> Void
    let onConfirm: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Text(title)
                .font(RecapFont.pretendard(size: 16, weight: .semibold))
                .tracking(-0.32)
                .foregroundStyle(RecapTheme.ColorToken.textPrimary)

            Text(message)
                .font(RecapFont.pretendard(size: 14, weight: .regular))
                .tracking(-0.28)
                .multilineTextAlignment(.center)
                .foregroundStyle(RecapTheme.ColorToken.textSecondary)
                .lineSpacing(4)
                .padding(.top, 10)

            HStack(spacing: 14) {
                dialogButton(
                    title: cancelTitle,
                    foreground: RecapTheme.ColorToken.textBody,
                    background: RecapTheme.ColorToken.controlFill,
                    action: onCancel
                )

                dialogButton(
                    title: confirmTitle,
                    foreground: .white,
                    background: CardDetailStyle.destructive,
                    action: onConfirm
                )
            }
            .padding(.top, 22)
        }
        .padding(.horizontal, 21)
        .padding(.top, 25)
        .frame(width: 292, height: 181, alignment: .top)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func dialogButton(
        title: String,
        foreground: Color,
        background: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(title)
                .font(RecapFont.pretendard(size: 14, weight: .medium))
                .tracking(-0.28)
                .foregroundStyle(foreground)
                .frame(maxWidth: .infinity)
                .frame(height: 45)
                .background(background)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

#Preview("정보카드 삭제 확인") {
    CardConfirmationDialog(
        title: "정보카드를 삭제할까요?",
        message: "삭제한 정보카드는 복구할 수 없어요.",
        cancelTitle: "취소",
        confirmTitle: "삭제",
        onCancel: {},
        onConfirm: {}
    )
    .padding()
    .background(CardDetailStyle.dim)
}
