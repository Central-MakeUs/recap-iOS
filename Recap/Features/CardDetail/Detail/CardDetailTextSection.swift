import SwiftUI

struct CardDetailTextSection: View {
    let card: Card
    let contentWidth: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            CardDetailCategoryAndDateRow(card: card)

            Text(card.title)
                .font(RecapFont.pretendard(size: 22, weight: .semibold))
                .tracking(-0.44)
                .foregroundStyle(Color.recapGray900)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 24)

            Text(card.summary)
                .font(RecapFont.pretendard(size: 15, weight: .medium))
                .tracking(-0.3)
                .foregroundStyle(Color.recapGray700)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 8)

            Text(card.memo)
                .font(RecapFont.pretendard(size: 15, weight: .medium))
                .tracking(-0.3)
                .lineSpacing(3)
                .foregroundStyle(Color.recapGray700)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 40)
        }
        .frame(
            width: contentWidth - (CardDetailStyle.horizontalPadding * 2),
            alignment: .leading
        )
        .padding(.horizontal, CardDetailStyle.horizontalPadding)
        .padding(.bottom, 40)
    }
}

#if DEBUG
#Preview("정보카드 텍스트") {
    CardDetailTextSection(
        card: Card(snapshot: SampleData.cards[1]),
        contentWidth: 375
    )
}
#endif
