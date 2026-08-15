import SwiftUI

struct CardEditOriginalPreview: View {
    let card: Card
    let onOpenOriginal: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(card.organizedFullDateText)
                .font(RecapFont.pretendard(size: 12, weight: .medium))
                .tracking(-0.24)
                .foregroundStyle(Color.recapGray300)
                .padding(.top, 10)
                .padding(.bottom, 8)

            CardDetailImageCard(onExpand: onOpenOriginal) {
                RecapScreenshotThumbnail(
                    category: card.category,
                    assetName: card.detailImageAssetName,
                    remoteURL: card.originalImageURL ?? card.thumbnailURL
                )
            }

            Text("원본 이미지는 수정 할 수 없어요. 텍스트 정보만 편집 가능해요")
                .font(RecapFont.pretendard(size: 10, weight: .semibold))
                .tracking(-0.2)
                .foregroundStyle(Color.recapBlue500)
                .padding(.top, 8)
        }
    }
}

#if DEBUG
#Preview("정보카드 수정 원본") {
    CardEditOriginalPreview(card: Card(snapshot: SampleData.cards[1]), onOpenOriginal: {})
        .padding(.horizontal, 16)
}
#endif
