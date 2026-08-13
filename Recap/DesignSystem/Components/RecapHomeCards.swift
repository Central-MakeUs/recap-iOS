import SwiftUI

struct RecapHomeRecentCard: View {
    let card: Card

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            RecapScreenshotThumbnail(
                kind: card.collection,
                assetName: card.thumbnailAssetName,
                remoteURL: card.thumbnailURL,
                size: CGSize(width: 134, height: 85),
                fallbackStyle: .folderCharacter
            )

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
    let card: Card

    var body: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack(alignment: .top) {
                RecapChip(configuration: .category(card.collection, size: .medium))

                Spacer(minLength: 0)

                RecapIconView(
                    icon: .forward,
                    size: 16,
                    color: Color.recapGray200
                )
                .padding(.top, 4)
            }

            Text(card.title)
                .font(RecapFont.pretendard(size: 14, weight: .semibold))
                .tracking(-0.28)
                .foregroundStyle(Color.recapGray900)
                .lineLimit(1)
        }
        .padding(13)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 85, alignment: .topLeading)
        .background(Color.recapGray50)
        .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
    }
}

#if DEBUG
#Preview("홈 카드") {
    ScrollView(.horizontal, showsIndicators: false) {
        HStack(alignment: .top, spacing: 16) {
            RecapHomeRecentCard(card: Card(snapshot: SampleData.cards[2]))
            RecapHomeFavoriteCard(card: Card(snapshot: SampleData.cards[3]))
        }
        .padding()
    }
}

#Preview("최근 정리 카드 썸네일 폴백") {
    RecapScreenshotThumbnail(
        kind: .knowledge,
        assetName: nil,
        size: CGSize(width: 134, height: 85),
        fallbackStyle: .folderCharacter
    )
    .padding()
}
#endif
