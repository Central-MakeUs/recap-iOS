import SwiftUI

struct RecapImageCard: View {
    let category: CardCategory
    var assetName: String?
    var isFavorite = false

    var body: some View {
        ZStack(alignment: .topTrailing) {
            RecapScreenshotThumbnail(category: category, assetName: assetName)
                .frame(width: 62, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))

            if isFavorite {
                RecapIconView(icon: .star, size: 24, color: Color.recapBlue300)
                    .offset(x: 0, y: 0)
            }
        }
        .frame(width: 62, height: 80)
    }
}

#if DEBUG
#Preview("이미지 카드") {
    HStack(spacing: 16) {
        RecapImageCard(
            category: .shopping,
            assetName: SampleData.cards[0].thumbnailAssetName
        )
        RecapImageCard(
            category: .capture,
            assetName: SampleData.cards[3].thumbnailAssetName,
            isFavorite: true
        )
    }
    .padding()
}
#endif
