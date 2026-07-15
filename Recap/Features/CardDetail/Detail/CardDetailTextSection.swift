import SwiftUI

struct CardDetailTextSection: View {
    let card: InformationCard
    let displaysCategoryPill: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            CardDetailCategoryAndDateRow(
                card: card,
                displaysCategoryPill: displaysCategoryPill
            )

            Text(card.title)
                .font(RecapFont.pretendard(size: 22, weight: .semibold))
                .tracking(-0.44)
                .foregroundStyle(RecapTheme.ColorToken.textPrimary)
                .padding(.top, 24)

            Text(card.summary)
                .font(RecapFont.pretendard(size: 15, weight: .medium))
                .tracking(-0.3)
                .foregroundStyle(RecapTheme.ColorToken.textBody)
                .padding(.top, 8)

            Text(card.memo)
                .font(RecapFont.pretendard(size: 15, weight: .medium))
                .tracking(-0.3)
                .lineSpacing(3)
                .foregroundStyle(RecapTheme.ColorToken.textBody)
                .padding(.top, 40)
        }
        .padding(.horizontal, CardDetailStyle.horizontalPadding)
        .padding(.bottom, 40)
    }
}

#Preview("정보카드 텍스트") {
    CardDetailTextSection(
        card: SampleData.cards[1],
        displaysCategoryPill: false
    )
}
