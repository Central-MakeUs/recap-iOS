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
        Button(action: onExpand) {
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

                CardExpandIcon()
                    .padding(.trailing, 24)
                    .padding(.bottom, 13)
            }
            .contentShape(Rectangle())
        }
        .frame(height: CardDetailStyle.heroHeight)
        .buttonStyle(.plain)
        .accessibilityLabel("원본 이미지 전체 보기")
    }
}

#Preview("정보카드 히어로") {
    CardDetailHeroView(onExpand: {}) {
        Color.gray
    }
}
