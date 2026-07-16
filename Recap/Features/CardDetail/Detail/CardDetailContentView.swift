import SwiftUI

struct CardDetailContentView: View {
    let card: InformationCard
    let imageState: CardDetailImageState
    let onOpenOriginal: () -> Void

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                CardDetailImageSection(
                    card: card,
                    imageState: imageState,
                    onOpenOriginal: onOpenOriginal
                )
                .padding(.top, imageState.imageTopInset)

                CardDetailTextSection(card: card)
                .padding(.top, imageState.metadataSpacing)
            }
        }
    }
}

#Preview("정보카드 상세 콘텐츠") {
    CardDetailContentView(
        card: SampleData.cards[1],
        imageState: .loaded,
        onOpenOriginal: {}
    )
}
