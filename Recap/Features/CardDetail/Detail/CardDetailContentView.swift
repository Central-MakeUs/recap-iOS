import SwiftUI

struct CardDetailContentView: View {
    let card: InformationCard
    let imageState: CardDetailImageState
    let contentWidth: CGFloat
    let onOpenOriginal: () -> Void

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                CardDetailImageSection(
                    card: card,
                    imageState: imageState,
                    onOpenOriginal: onOpenOriginal
                )
                .frame(width: contentWidth)
                .padding(.top, imageState.imageTopInset)

                CardDetailTextSection(
                    card: card,
                    contentWidth: contentWidth
                )
                .padding(.top, imageState.metadataSpacing)
            }
            .frame(width: contentWidth, alignment: .leading)
        }
        .frame(width: contentWidth)
    }
}

#Preview("정보카드 상세 콘텐츠") {
    CardDetailContentView(
        card: SampleData.cards[1],
        imageState: .loaded,
        contentWidth: 375,
        onOpenOriginal: {}
    )
}
