import SwiftUI

struct AllRecentCardRow: View {
    let card: InformationCard
    var onToggleFavorite: (() -> Void)?

    var body: some View {
        RecapInformationCardRow(
            card: card,
            onToggleFavorite: onToggleFavorite
        )
    }
}

#Preview("전체 최신 카드 행") {
    VStack(spacing: 0) {
        ForEach(SampleData.recentCards) { card in
            AllRecentCardRow(card: card)
        }
    }
}
