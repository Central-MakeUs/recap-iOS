import SwiftUI

struct AllRecentCardRow: View {
    let card: InformationCard

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                RecapChip(configuration: .category(card.collection, size: .small))

                VStack(alignment: .leading, spacing: 2) {
                    Text(card.title)
                        .font(RecapFont.pretendard(size: 14, weight: .semibold))
                        .tracking(-0.28)
                        .foregroundStyle(Color.recapGray900)
                        .lineLimit(1)

                    Text(card.summary)
                        .font(RecapFont.pretendard(size: 13, weight: .medium))
                        .tracking(-0.26)
                        .foregroundStyle(Color.recapGray500)
                        .lineLimit(2)
                }
            }
            .frame(width: 237, alignment: .leading)

            Spacer(minLength: 0)

            RecapScreenshotThumbnail(
                kind: card.collection,
                assetName: card.thumbnailAssetName,
                remoteURL: card.thumbnailURL
            )
            .frame(width: 62, height: 80)
            .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
            .overlay(alignment: .topTrailing) {
                RecapIconView(
                    icon: card.isFavorite ? .star : .starEmpty,
                    size: 24,
                    color: card.isFavorite ? Color.recapBlue300 : Color.recapGray100
                )
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity)
        .frame(height: 108, alignment: .top)
        .background(Color.white)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.recapGray100)
                .frame(height: 1)
        }
    }
}

#Preview("전체 최신 카드 행") {
    VStack(spacing: 0) {
        ForEach(SampleData.recentCards) { card in
            AllRecentCardRow(card: card)
        }
    }
}
