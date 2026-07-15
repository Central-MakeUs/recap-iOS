import SwiftUI

struct CardFeedback: Hashable {
    let kind: CardFeedbackToast.Kind
    let message: String
}

struct CardFeedbackToast: View {
    enum Kind: Hashable {
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

extension View {
    func cardFeedbackToast(
        _ feedback: CardFeedback?,
        horizontalPadding: CGFloat,
        bottomPadding: CGFloat
    ) -> some View {
        overlay(alignment: .bottom) {
            if let feedback {
                CardFeedbackToast(kind: feedback.kind, message: feedback.message)
                    .padding(.horizontal, horizontalPadding)
                    .padding(.bottom, bottomPadding)
            }
        }
    }
}

#Preview("정보카드 성공 토스트") {
    CardFeedbackToast(kind: .success, message: "즐겨찾기에 추가했어요")
}

#Preview("정보카드 실패 토스트") {
    CardFeedbackToast(kind: .failure, message: "삭제하지 못했어요")
}
