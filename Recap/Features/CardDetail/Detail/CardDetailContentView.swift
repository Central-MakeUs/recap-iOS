import SwiftUI

struct CardDetailContentView: View {
    let card: Card
    let onOpenOriginal: () -> Void
    var onRemoteImageFailure: (URL) -> Void = { _ in }

    var body: some View {
        // 세로 여백이 고정이면 SE에서 제목이 화면 한가운데 아래로 내려간다.
        // 여백만 화면 높이 비율로 맞춰 기기마다 같은 자리에 오게 한다.
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                CardDetailImageSection(
                    card: card,
                    onOpenOriginal: onOpenOriginal,
                    onRemoteImageFailure: onRemoteImageFailure
                )
                .designScaledTopPadding(33)

                CardDetailTextSection(card: card)
                    .designScaledTopPadding(18)
            }
            .frame(maxWidth: .infinity)
        }
        .measuringDesignHeightScale()
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
