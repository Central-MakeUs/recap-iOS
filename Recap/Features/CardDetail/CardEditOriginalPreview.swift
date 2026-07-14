import SwiftUI

struct CardEditOriginalPreview: View {
    let card: InformationCard
    let onOpenOriginal: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(card.dateText)
                .font(RecapFont.pretendard(size: 12, weight: .medium))
                .tracking(-0.24)
                .foregroundStyle(RecapTheme.ColorToken.textTertiary)
                .padding(.top, 10)
                .padding(.bottom, 8)

            ZStack(alignment: .bottomTrailing) {
                RecapScreenshotThumbnail(kind: card.collection, assetName: card.detailImageAssetName)
                    .frame(height: CardDetailStyle.imageCardHeight)
                    .frame(maxWidth: .infinity)
                    .clipped()

                CardExpandButton(
                    foregroundColor: RecapTheme.ColorToken.textTertiary,
                    backgroundColor: .white,
                    action: onOpenOriginal
                )
                .padding(.trailing, 8)
                .padding(.bottom, 8)
            }
            .clipShape(RoundedRectangle(cornerRadius: CardDetailStyle.cornerRadius, style: .continuous))

            Text("원본 이미지는 수정 할 수 없어요. 텍스트 정보만 편집 가능해요")
                .font(RecapFont.pretendard(size: 10, weight: .semibold))
                .tracking(-0.2)
                .foregroundStyle(Color(red: 56 / 255, green: 69 / 255, blue: 199 / 255))
                .padding(.top, 8)
        }
    }
}

#Preview("정보카드 수정 원본") {
    CardEditOriginalPreview(card: SampleData.cards[1], onOpenOriginal: {})
        .padding(.horizontal, 16)
}
