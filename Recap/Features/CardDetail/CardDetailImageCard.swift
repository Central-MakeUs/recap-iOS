import SwiftUI

struct CardDetailImageCard<Content: View>: View {
    let onExpand: () -> Void
    let content: Content

    init(
        onExpand: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.onExpand = onExpand
        self.content = content()
    }

    var body: some View {
        content
            .frame(height: CardDetailStyle.imageCardHeight)
            .frame(maxWidth: .infinity)
            .clipped()
            .overlay(alignment: .bottomTrailing) {
                CardExpandButton(
                    foregroundColor: RecapTheme.ColorToken.textTertiary,
                    backgroundColor: .white,
                    action: onExpand
                )
                .padding(.trailing, 8)
                .padding(.bottom, 8)
            }
            .clipShape(
                RoundedRectangle(
                    cornerRadius: CardDetailStyle.cornerRadius,
                    style: .continuous
                )
            )
    }
}

#Preview("정보카드 이미지 카드") {
    CardDetailImageCard(onExpand: {}) {
        Color.gray
    }
    .padding(.horizontal, CardDetailStyle.horizontalPadding)
}
