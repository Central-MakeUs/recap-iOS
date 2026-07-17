import SwiftUI

struct ArchiveCardListRow: View {
    enum Metadata {
        case category
        case organizedDate
    }

    let card: InformationCard
    var metadata: Metadata = .category
    var favoriteOverride: Bool?
    var selectionState: Bool?
    var thumbnailCornerRadius: CGFloat = 5

    var body: some View {
        Group {
            if let selectionState {
                selectionRow(isSelected: selectionState)
            } else {
                browsingRow
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 108, alignment: .top)
        .background(Color.white)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.recapGray100)
                .frame(height: 1)
        }
    }

    private var browsingRow: some View {
        HStack(alignment: .top, spacing: 0) {
            textContent

            Spacer(minLength: 0)

            ZStack(alignment: .topTrailing) {
                thumbnail

                RecapIconView(
                    icon: (favoriteOverride ?? card.isFavorite) ? .star : .starEmpty,
                    size: 24,
                    color: (favoriteOverride ?? card.isFavorite)
                        ? Color.recapBlue300
                        : Color.recapGray100
                )
            }
            .padding(.top, 14)
        }
    }

    private func selectionRow(isSelected: Bool) -> some View {
        HStack(alignment: .top, spacing: 14) {
            RecapIconView(
                icon: .checkbox,
                size: 16,
                color: isSelected ? Color.recapBlue300 : Color.recapGray100
            )
            .padding(.top, 14)

            textContent

            thumbnail
                .padding(.top, 14)
        }
    }

    private var textContent: some View {
        VStack(alignment: .leading, spacing: metadata == .category ? 4 : 2) {
            if metadata == .category {
                Text(RecapPresentation.collectionDisplay(for: card.collection).title)
                    .font(RecapFont.pretendard(size: 10, weight: .semibold))
                    .tracking(-0.2)
                    .foregroundStyle(
                        RecapPresentation.collectionDisplay(for: card.collection).textColor
                    )
            }

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

            if metadata == .organizedDate {
                Text(card.dateText.replacingOccurrences(of: "정리됨 ", with: "") + " 정리")
                    .font(RecapFont.pretendard(size: 10, weight: .semibold))
                    .tracking(-0.2)
                    .foregroundStyle(Color.recapGray300)
                    .padding(.top, 3)
            }
        }
        .frame(width: 237, alignment: .leading)
        .padding(.top, 14)
    }

    private var thumbnail: some View {
        RecapScreenshotThumbnail(
            kind: card.collection,
            assetName: card.thumbnailAssetName,
            cornerRadius: thumbnailCornerRadius
        )
        .frame(width: 62, height: 80)
    }
}

struct RecapScreenshotThumbnail: View {
    let kind: CollectionKind
    var assetName: String?
    var cornerRadius: CGFloat = 5

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
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .clipped()
        .overlay {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
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
    ArchiveCardListRow(card: SampleData.cards[3], favoriteOverride: true)
}

#Preview("보관함 날짜 리스트 카드") {
    ArchiveCardListRow(card: SampleData.cards[0], metadata: .organizedDate)
}

#Preview("스크린샷 썸네일") {
    RecapScreenshotThumbnail(
        kind: .shopping,
        assetName: SampleData.cards[0].thumbnailAssetName
    )
    .frame(width: 134, height: 85)
    .padding()
}
