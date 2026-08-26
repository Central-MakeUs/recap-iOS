import SwiftUI

struct RecapConfirmationDialog: View {
    let title: String
    let message: String
    let cancelTitle: String
    let confirmTitle: String
    let confirmStyle: RecapPopupButton.Style
    let height: CGFloat
    let onCancel: () -> Void
    let onConfirm: () -> Void

    init(
        title: String,
        message: String,
        cancelTitle: String,
        confirmTitle: String,
        confirmStyle: RecapPopupButton.Style = .destructive,
        height: CGFloat = 181,
        onCancel: @escaping () -> Void,
        onConfirm: @escaping () -> Void
    ) {
        self.title = title
        self.message = message
        self.cancelTitle = cancelTitle
        self.confirmTitle = confirmTitle
        self.confirmStyle = confirmStyle
        self.height = height
        self.onCancel = onCancel
        self.onConfirm = onConfirm
    }

    var body: some View {
        VStack(spacing: 0) {
            Text(title)
                .font(RecapFont.pretendard(size: 16, weight: .semibold))
                .tracking(-0.32)
                .foregroundStyle(Color.recapGray900)

            Text(message)
                .font(RecapFont.pretendard(size: 14, weight: .regular))
                .tracking(-0.28)
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.recapGray500)
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
                    style: confirmStyle,
                    action: onConfirm
                )
            }
            .padding(.top, 22)
        }
        .padding(.horizontal, 21)
        .padding(.top, 25)
        .frame(width: 292, height: height, alignment: .top)
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
        confirmStyle: RecapPopupButton.Style = .destructive,
        height: CGFloat = 181,
        onConfirm: @escaping () -> Void
    ) -> some View {
        modifier(
            RecapConfirmationDialogModifier(
                isPresented: isPresented,
                title: title,
                message: message,
                cancelTitle: cancelTitle,
                confirmTitle: confirmTitle,
                confirmStyle: confirmStyle,
                height: height,
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
    let confirmStyle: RecapPopupButton.Style
    let height: CGFloat
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
                        confirmStyle: confirmStyle,
                        height: height,
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

#if DEBUG
#Preview("확인 팝업") {
    RecapConfirmationDialog(
        title: "스크린샷을 삭제할까요?",
        message: "삭제한 스크린샷 정보는\n되돌릴 수 없어요.",
        cancelTitle: "취소",
        confirmTitle: "삭제",
        confirmStyle: .destructive,
        height: 181,
        onCancel: {},
        onConfirm: {}
    )
    .padding()
    .background(Color.black.opacity(0.30))
}
#endif
