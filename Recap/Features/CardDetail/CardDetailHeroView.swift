import SwiftUI

struct CardDetailHeroView<HeroImage: View>: View {
    let onExpand: () -> Void
    let heroImage: HeroImage

    init(
        onExpand: @escaping () -> Void,
        @ViewBuilder heroImage: () -> HeroImage
    ) {
        self.onExpand = onExpand
        self.heroImage = heroImage()
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            heroImage

            LinearGradient(
                stops: [
                    .init(color: Color.black.opacity(0.90), location: 0),
                    .init(color: Color.black.opacity(0), location: 1)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: CardDetailStyle.heroGradientHeight)
            .frame(maxHeight: .infinity, alignment: .top)

            CardExpandButton(action: onExpand)
                .padding(.trailing, 24)
                .padding(.bottom, 13)
        }
        .frame(height: CardDetailStyle.heroHeight)
    }
}

#Preview("정보카드 히어로") {
    CardDetailHeroView(onExpand: {}) {
        Color.gray
    }
}
