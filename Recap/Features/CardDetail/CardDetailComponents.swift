import SwiftUI

struct CardImageFailureView: View {
    var body: some View {
        VStack(spacing: 7) {
            Image(systemName: "photo.badge.exclamationmark")
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(RecapTheme.ColorToken.textTertiary)
                .frame(width: 24, height: 24)

            Text("원본 이미지를 불러오지 못했어요")
                .font(RecapFont.pretendard(size: 14, weight: .regular))
                .tracking(-0.28)
                .foregroundStyle(RecapTheme.ColorToken.textTertiary)
        }
    }
}

struct CardExpandButton: View {
    var foregroundColor: Color = .white
    var backgroundColor: Color = .black.opacity(0.28)
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "arrow.up.left.and.arrow.down.right")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(foregroundColor)
                .frame(width: 21, height: 21)
                .background(backgroundColor)
                .overlay {
                    RoundedRectangle(cornerRadius: 2)
                        .stroke(CardDetailStyle.inputBorder, lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("원본 이미지 전체 보기")
    }
}

struct CardFeedbackToast: View {
    enum Kind {
        case success
        case failure
    }

    let kind: Kind
    let message: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: kind == .success ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(kind == .success ? CardDetailStyle.success : CardDetailStyle.destructive)

            Text(message)
                .font(RecapFont.pretendard(size: 13, weight: .medium))
                .tracking(-0.26)
                .foregroundStyle(.white)
                .lineLimit(1)
        }
        .padding(.horizontal, 22)
        .frame(height: 45)
        .background(CardDetailStyle.toastBackground)
        .clipShape(Capsule())
    }
}

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
