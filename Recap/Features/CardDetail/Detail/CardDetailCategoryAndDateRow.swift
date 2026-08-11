import SwiftUI

struct CardDetailCategoryAndDateRow: View {
    let card: InformationCard

    var body: some View {
        HStack {
            Text(RecapPresentation.collectionDisplay(for: card.collection).title)
                .font(RecapFont.pretendard(size: 14, weight: .semibold))
                .tracking(-0.28)
                .foregroundStyle(
                    RecapPresentation.collectionDisplay(for: card.collection).textColor
                )

            Spacer()

            Text(RecapPresentation.organizedDateText(for: card))
                .font(RecapFont.pretendard(size: 12, weight: .medium))
                .tracking(-0.24)
                .foregroundStyle(Color.recapGray300)
        }
    }
}

#if DEBUG
#Preview("정보카드 카테고리 및 날짜") {
    CardDetailCategoryAndDateRow(card: SampleData.cards[1])
    .padding()
}
#endif
