import SwiftUI

struct CardDetailCategoryAndDateRow: View {
    let card: InformationCard
    let displaysCategoryPill: Bool

    var body: some View {
        HStack {
            if displaysCategoryPill {
                RecapCategoryPill(kind: card.collection, size: .regular)
            } else {
                Text(RecapPresentation.collectionDisplay(for: card.collection).title)
                    .font(RecapFont.pretendard(size: 14, weight: .semibold))
                    .tracking(-0.28)
                    .foregroundStyle(
                        RecapPresentation.collectionDisplay(for: card.collection).textColor
                    )
            }

            Spacer()

            Text(card.dateText)
                .font(RecapFont.pretendard(size: 12, weight: .medium))
                .tracking(-0.24)
                .foregroundStyle(RecapTheme.ColorToken.textTertiary)
        }
    }
}

#Preview("정보카드 카테고리 및 날짜") {
    CardDetailCategoryAndDateRow(
        card: SampleData.cards[1],
        displaysCategoryPill: false
    )
    .padding()
}
