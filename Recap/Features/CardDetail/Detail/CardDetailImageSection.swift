import SwiftUI

struct CardDetailImageSection: View {
    let card: InformationCard
    let imageState: CardDetailImageState
    let onOpenOriginal: () -> Void

    @ViewBuilder
    var body: some View {
        switch imageState {
        case .loaded:
            CardDetailHeroView(onExpand: onOpenOriginal) {
                RecapScreenshotThumbnail(
                    kind: card.collection,
                    assetName: card.detailImageAssetName
                )
                .frame(height: CardDetailStyle.heroHeight)
                .frame(maxWidth: .infinity)
                .clipped()
            }
        case .failedFullWidth:
            CardDetailHeroView(onExpand: onOpenOriginal) {
                ZStack {
                    LinearGradient(
                        colors: [Color.recapImageFailureFill, .white],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    CardImageFailureView()
                }
                .frame(height: CardDetailStyle.heroHeight)
            }
        case .failedCard:
            CardDetailFailedImageCard(onExpand: onOpenOriginal)
        }
    }
}

#Preview("정보카드 이미지 - 로딩 실패") {
    CardDetailImageSection(
        card: SampleData.cards[1],
        imageState: .failedCard,
        onOpenOriginal: {}
    )
}
