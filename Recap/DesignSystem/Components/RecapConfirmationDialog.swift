import SwiftUI

struct RecapConfirmationDialog: View {
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
                RecapPopupButton(
                    title: cancelTitle,
                    style: .secondary,
                    action: onCancel
                )

                RecapPopupButton(
                    title: confirmTitle,
                    style: .destructive,
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
}

extension View {
    func recapConfirmationDialog(
        isPresented: Binding<Bool>,
        title: String,
        message: String,
        cancelTitle: String,
        confirmTitle: String,
        onConfirm: @escaping () -> Void
    ) -> some View {
        modifier(
            RecapConfirmationDialogModifier(
                isPresented: isPresented,
                title: title,
                message: message,
                cancelTitle: cancelTitle,
                confirmTitle: confirmTitle,
                onConfirm: onConfirm
            )
        )
    }
}

private struct RecapConfirmationDialogModifier: ViewModifier {
    @Binding var isPresented: Bool

    let title: String
    let message: String
    let cancelTitle: String
    let confirmTitle: String
    let onConfirm: () -> Void

    func body(content: Content) -> some View {
        content.overlay {
            if isPresented {
                ZStack {
                    Color.black.opacity(0.30)
                        .ignoresSafeArea()

                    RecapConfirmationDialog(
                        title: title,
                        message: message,
                        cancelTitle: cancelTitle,
                        confirmTitle: confirmTitle,
                        onCancel: dismiss,
                        onConfirm: confirm
                    )
                }
            }
        }
    }

    private func dismiss() {
        isPresented = false
    }

    private func confirm() {
        isPresented = false
        onConfirm()
    }
}

#Preview("확인 팝업") {
    RecapConfirmationDialog(
        title: "스크린샷을 삭제할까요?",
        message: "삭제한 스크린샷 정보는\n되돌릴 수 없어요.",
        cancelTitle: "취소",
        confirmTitle: "삭제",
        onCancel: {},
        onConfirm: {}
    )
    .padding()
    .background(Color.black.opacity(0.30))
}
