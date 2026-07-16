import SwiftUI

struct RecapInformationCardRow: View {
    enum Metadata {
        case category
        case organizedDate
    }

    let card: InformationCard
    var metadata: Metadata = .category
    var selectionState: Bool?

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            if let selectionState {
                RecapIconView(
                    icon: .checkbox,
                    size: 16,
                    color: selectionState ? Color.recapBlue300 : Color.recapGray100
                )
            }

            VStack(alignment: .leading, spacing: metadata == .category ? 8 : 5) {
                if metadata == .category {
                    RecapChip(configuration: .category(card.collection, size: .small))
                }

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

                if metadata == .organizedDate {
                    Text(card.dateText.replacingOccurrences(of: "정리됨 ", with: "") + " 정리")
                        .font(RecapFont.pretendard(size: 10, weight: .semibold))
                        .tracking(-0.2)
                        .foregroundStyle(Color.recapGray300)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            RecapIconView(
                icon: card.isFavorite ? .star : .starEmpty,
                size: 24,
                color: card.isFavorite ? Color.recapBlue300 : Color.recapGray100
            )
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

#Preview("정보카드 행") {
    VStack(spacing: 0) {
        RecapInformationCardRow(card: SampleData.cards[2])
        RecapInformationCardRow(
            card: SampleData.cards[3],
            metadata: .organizedDate,
            selectionState: true
        )
    }
}
