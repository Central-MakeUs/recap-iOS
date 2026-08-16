import SwiftUI

struct RecapInformationCardRow: View {
    enum Metadata {
        case category
        case organizedDate
    }

    let card: Card
    var metadata: Metadata = .category
    var selectionState: Bool?
    var titleText: Text?
    var summaryText: Text?
    var onToggleFavorite: (() -> Void)?

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
        // 행을 화면과 같은 색으로 둔다. 행을 나누는 것은 아래 구분선이다.
        // 투명하게 두지 않는 것은 행이 무엇 위에 놓이든 같아 보여야 하기 때문이다.
        .background(Color.recapBackground)
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
        .frame(height: 80, alignment: .top)
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
                category: card.category,
                assetName: card.thumbnailAssetName,
                remoteURL: card.thumbnailURL,
                hasFavoriteFold: true,
                size: CGSize(width: 62, height: 80),
                fallbackStyle: .character
            )

            RecapIconView(
                icon: card.isFavorite ? .star : .starEmpty,
                size: 24,
                color: card.isFavorite ? Color.recapBlue300 : Color.recapGray100
            )
        }
        .frame(width: 62, height: 80)
        .overlay(alignment: .topTrailing) {
            if let onToggleFavorite {
                Button(action: onToggleFavorite) {
                    Color.clear
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(card.isFavorite ? "즐겨찾기 해제" : "즐겨찾기 추가")
            }
        }
    }

    private var selectedThumbnail: some View {
        RecapScreenshotThumbnail(
            category: card.category,
            assetName: card.thumbnailAssetName,
            remoteURL: card.thumbnailURL,
            cornerRadius: 0,
            fallbackStyle: .character
        )
        .frame(width: 62, height: 80)
        .clipped()
    }

    @ViewBuilder
    private var cardContent: some View {
        switch metadata {
        case .category:
            VStack(alignment: .leading, spacing: 8) {
                RecapChip(configuration: .category(card.category, size: .small))
                titleAndSummary
            }
        case .organizedDate:
            VStack(alignment: .leading, spacing: 0) {
                titleAndSummary
                Spacer(minLength: 0)
                Text(card.organizedDateText)
                    .font(RecapFont.pretendard(size: 10, weight: .semibold))
                    .tracking(-0.2)
                    .foregroundStyle(Color.recapGray300)
                    .frame(height: 14, alignment: .topLeading)
            }
        }
    }

    private var titleAndSummary: some View {
        VStack(alignment: .leading, spacing: 2) {
            (titleText ?? Text(card.title.recapWordUnitWrapped))
                .font(RecapFont.pretendard(size: 14, weight: .semibold))
                .tracking(-0.28)
                .foregroundStyle(Color.recapGray900)
                .lineLimit(1)
                .frame(height: 20, alignment: .topLeading)

            (summaryText ?? Text(card.summary.recapWordUnitWrapped))
                .font(RecapFont.pretendard(size: 13, weight: .medium))
                .tracking(-0.26)
                .foregroundStyle(Color.recapGray500)
                .lineLimit(2)
                .frame(height: 36, alignment: .topLeading)
        }
        .frame(height: 58, alignment: .topLeading)
    }

}

private extension String {
    var recapWordUnitWrapped: String {
        split(separator: " ", omittingEmptySubsequences: false)
            .map { word in
                word.map(String.init).joined(separator: "\u{2060}")
            }
            .joined(separator: " ")
    }
}

#if DEBUG
#Preview("card/category") {
    RecapInformationCardRow(
        card: Card(snapshot: SampleData.cards[2]))
}

#Preview("card/nocategory") {
    RecapInformationCardRow(
        card: Card(snapshot: SampleData.cards[3]),
        metadata: .organizedDate
    )
}

#Preview("card/category/selected") {
    RecapInformationCardRow(
        card: Card(snapshot: SampleData.cards[2]),
        selectionState: true
    )
}

#Preview("card/nocategory/selected") {
    RecapInformationCardRow(
        card: Card(snapshot: SampleData.cards[3]),
        metadata: .organizedDate,
        selectionState: true
    )
}

#Preview("card/nocategory - 320pt") {
    RecapInformationCardRow(
        card: Card(snapshot: SampleData.cards[2]),
        metadata: .organizedDate
    )
    .frame(width: 320)
}

#Preview("card/nocategory - 430pt") {
    RecapInformationCardRow(
        card: Card(snapshot: SampleData.cards[2]),
        metadata: .organizedDate
    )
    .frame(width: 430)
}
#endif
