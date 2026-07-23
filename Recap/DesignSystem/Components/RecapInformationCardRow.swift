import SwiftUI

struct RecapInformationCardRow: View {
    enum Metadata {
        case category
        case organizedDate
    }

    let card: InformationCard
    var metadata: Metadata = .category
    var favoriteOverride: Bool?
    var selectionState: Bool?

    var body: some View {
        Group {
            if let selectionState {
                selectedLayout(isSelected: selectionState)
            } else {
                defaultLayout
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

    private var defaultLayout: some View {
        HStack(alignment: .top, spacing: 0) {
            cardContent
                .frame(width: 237, height: 80, alignment: .topLeading)

            Spacer(minLength: 0)

            thumbnailAndFavorite
        }
    }

    private func selectedLayout(isSelected: Bool) -> some View {
        HStack(alignment: .top, spacing: 14) {
            RecapIconView(
                icon: .checkbox,
                size: 16,
                color: isSelected ? Color.recapBlue300 : Color.recapGray100
            )

            cardContent
                .frame(width: 237, height: 80, alignment: .topLeading)

            selectedThumbnail
        }
    }

    private var thumbnailAndFavorite: some View {
        ZStack(alignment: .topTrailing) {
            RecapScreenshotThumbnail(
                kind: card.collection,
                assetName: card.thumbnailAssetName,
                remoteURL: card.thumbnailURL,
                hasFavoriteFold: true
            )
            .frame(width: 62, height: 80)
            .clipped()

            let isFavorite = favoriteOverride ?? card.isFavorite
            RecapIconView(
                icon: isFavorite ? .star : .starEmpty,
                size: 24,
                color: isFavorite ? Color.recapBlue300 : Color.recapGray100
            )
        }
    }

    private var selectedThumbnail: some View {
        RecapScreenshotThumbnail(
            kind: card.collection,
            assetName: card.thumbnailAssetName,
            remoteURL: card.thumbnailURL,
            cornerRadius: 0
        )
        .frame(width: 62, height: 80)
        .clipped()
    }

    @ViewBuilder
    private var cardContent: some View {
        switch metadata {
        case .category:
            VStack(alignment: .leading, spacing: 8) {
                RecapChip(configuration: .category(card.collection, size: .small))
                titleAndSummary
            }
        case .organizedDate:
            VStack(alignment: .leading, spacing: 0) {
                titleAndSummary
                Spacer(minLength: 0)
                Text(organizedDateText)
                    .font(RecapFont.pretendard(size: 10, weight: .semibold))
                    .tracking(-0.2)
                    .foregroundStyle(Color.recapGray300)
                    .frame(height: 14, alignment: .topLeading)
            }
        }
    }

    private var titleAndSummary: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(card.title)
                .font(RecapFont.pretendard(size: 14, weight: .semibold))
                .tracking(-0.28)
                .foregroundStyle(Color.recapGray900)
                .lineLimit(1)
                .frame(height: 20, alignment: .topLeading)

            Text(card.summary)
                .font(RecapFont.pretendard(size: 13, weight: .medium))
                .tracking(-0.26)
                .foregroundStyle(Color.recapGray500)
                .lineLimit(2)
                .frame(height: 36, alignment: .topLeading)
        }
        .frame(height: 58, alignment: .topLeading)
    }

    private var organizedDateText: String {
        card.dateText.replacingOccurrences(of: "정리됨 ", with: "") + " 정리"
    }
}

#Preview("card/category") {
    RecapInformationCardRow(card: SampleData.cards[2])
}

#Preview("card/nocategory") {
    RecapInformationCardRow(
        card: SampleData.cards[3],
        metadata: .organizedDate
    )
}

#Preview("card/category/selected") {
    RecapInformationCardRow(
        card: SampleData.cards[2],
        selectionState: true
    )
}

#Preview("card/nocategory/selected") {
    RecapInformationCardRow(
        card: SampleData.cards[3],
        metadata: .organizedDate,
        selectionState: true
    )
}
