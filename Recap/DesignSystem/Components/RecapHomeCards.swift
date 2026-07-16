import SwiftUI

struct RecapHomeRecentCard: View {
    let card: InformationCard

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            RecapScreenshotThumbnail(
                kind: card.collection,
                assetName: card.thumbnailAssetName
            )
            .frame(width: 134, height: 85)
            .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))

            VStack(alignment: .leading, spacing: 5) {
                RecapChip(configuration: .category(card.collection, size: .small))

                Text(card.title)
                    .font(RecapFont.pretendard(size: 13, weight: .medium))
                    .tracking(-0.26)
                    .foregroundStyle(Color.recapGray900)
                    .lineLimit(2)
            }
        }
        .frame(width: 134, height: 147, alignment: .topLeading)
    }
}

struct RecapHomeFavoriteCard: View {
    let card: InformationCard

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top) {
                RecapChip(configuration: .category(card.collection, size: .medium))

                Spacer(minLength: 0)

                RecapIconView(
                    icon: .forward,
                    size: 16,
                    color: Color.recapGray100
                )
            }

            Text(card.title)
                .font(RecapFont.pretendard(size: 14, weight: .semibold))
                .tracking(-0.28)
                .foregroundStyle(Color.recapGray900)
                .lineLimit(1)
        }
        .padding(13)
        .frame(width: 166, height: 85, alignment: .topLeading)
        .background(Color.recapGray50)
        .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
    }
}

#Preview("홈 카드") {
    ScrollView(.horizontal, showsIndicators: false) {
        HStack(alignment: .top, spacing: 16) {
            RecapHomeRecentCard(card: SampleData.cards[2])
            RecapHomeFavoriteCard(card: SampleData.cards[3])
        }
        .padding()
    }
}
