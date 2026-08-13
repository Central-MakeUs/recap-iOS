import SwiftUI

struct CardDetailContentView: View {
    let card: Card
    let onOpenOriginal: () -> Void
    var onRemoteImageFailure: (URL) -> Void = { _ in }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                CardDetailImageSection(
                    card: card,
                    onOpenOriginal: onOpenOriginal,
                    onRemoteImageFailure: onRemoteImageFailure
                )
                .padding(.top, 33)

                CardDetailTextSection(card: card)
                    .padding(.top, 18)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

#if DEBUG
#Preview("정보카드 상세 콘텐츠") {
    CardDetailContentView(
        card: Card(snapshot: SampleData.cards[1]),
        onOpenOriginal: {}
    )
}
#endif
