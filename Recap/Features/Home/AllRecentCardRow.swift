import SwiftUI

struct AllRecentCardRow: View {
    let card: InformationCard

    var body: some View {
        RecapInformationCardRow(card: card)
    }
}

#Preview("전체 최신 카드 행") {
    VStack(spacing: 0) {
        ForEach(SampleData.recentCards) { card in
            AllRecentCardRow(card: card)
        }
    }
}
