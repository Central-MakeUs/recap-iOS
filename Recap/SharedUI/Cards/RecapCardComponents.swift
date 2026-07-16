import SwiftUI

struct FavoriteRecapListCard: View {
    let card: InformationCard
    var isStarred = false

    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            RecapScreenshotThumbnail(kind: card.collection, assetName: card.thumbnailAssetName)
                .frame(width: 68, height: 68)
                .fixedSize(horizontal: true, vertical: true)
                .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
                .padding(.top, 13)

            VStack(alignment: .leading, spacing: 8) {
                RecapChip(configuration: .category(card.collection, size: .small))

                VStack(alignment: .leading, spacing: 3) {
                    Text(card.title)
                        .font(RecapFont.pretendard(size: 14, weight: .semibold))
                        .tracking(-0.28)
                        .foregroundStyle(Color.recapGray900)
                        .lineLimit(1)

                    Text(card.summary)
                        .font(RecapFont.pretendard(size: 13, weight: .medium))
                        .tracking(-0.26)
                        .foregroundStyle(Color.recapGray500)
                        .lineLimit(1)
                }
            }
            .padding(.top, 13)

            Spacer(minLength: 0)

            RecapIconView(
                icon: isStarred ? .star : .starEmpty,
                size: 24,
                color: isStarred ? Color.recapBlue300 : Color.recapGray100
            )
            .padding(.top, 10)
        }
        .padding(.horizontal, 16)
        .frame(height: 94, alignment: .top)
        .background(Color.white)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.recapGray100)
                .frame(height: 1)
        }
    }
}

struct RecapScreenshotThumbnail: View {
    let kind: CollectionKind
    var assetName: String?

    var body: some View {
        Group {
            if let assetName {
                Image(assetName)
                    .resizable()
                    .scaledToFill()
            } else {
                placeholder
            }
        }
        .clipped()
        .overlay {
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .stroke(Color.recapGray100, lineWidth: 1)
        }
    }

    private var placeholder: some View {
        let display = RecapPresentation.collectionDisplay(for: kind)

        return RoundedRectangle(cornerRadius: 5, style: .continuous)
            .fill(Color.recapThumbnail)
            .overlay(alignment: .topLeading) {
                Rectangle()
                    .fill(display.dotColor.opacity(0.20))
                    .frame(height: 18)
            }
            .overlay {
                Image(systemName: display.symbolName)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(display.textColor.opacity(0.55))
            }
    }
}

#Preview("즐겨찾기 리스트 카드") {
    FavoriteRecapListCard(card: SampleData.cards[3], isStarred: true)
}

#Preview("스크린샷 썸네일") {
    RecapScreenshotThumbnail(
        kind: .shopping,
        assetName: SampleData.cards[0].thumbnailAssetName
    )
    .frame(width: 134, height: 85)
    .padding()
}
