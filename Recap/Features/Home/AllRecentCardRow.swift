import SwiftUI

struct AllRecentCardRow: View {
    let card: Card
    var onToggleFavorite: (() -> Void)?

    var body: some View {
        RecapInformationCardRow(
            card: card,
            onToggleFavorite: onToggleFavorite
        )
    }
}

#if DEBUG
#Preview("전체 최신 카드 행") {
    VStack(spacing: 0) {
        ForEach(SampleData.recentCards.compactMap(Card.init(snapshot:))) { card in
            AllRecentCardRow(card: card)
        }
    }
}
#endif
