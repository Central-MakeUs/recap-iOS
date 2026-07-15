import SwiftUI

struct CardDetailFailedImageCard: View {
    let onExpand: () -> Void

    var body: some View {
        ZStack {
            CardDetailStyle.imageFailureFill
            CardImageFailureView()
        }
        .overlay(alignment: .bottomTrailing) {
            CardExpandButton(
                foregroundColor: RecapTheme.ColorToken.textTertiary,
                backgroundColor: .white,
                action: onExpand
            )
            .padding(.trailing, 8)
            .padding(.bottom, 8)
        }
        .frame(height: CardDetailStyle.imageCardHeight)
        .clipShape(
            RoundedRectangle(
                cornerRadius: CardDetailStyle.cornerRadius,
                style: .continuous
            )
        )
        .padding(.horizontal, CardDetailStyle.horizontalPadding)
    }
}

#Preview("정보카드 이미지 카드 로딩 실패") {
    CardDetailFailedImageCard(onExpand: {})
}
