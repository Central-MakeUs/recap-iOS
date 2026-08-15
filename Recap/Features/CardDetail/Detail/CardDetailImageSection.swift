import SwiftUI

/// 원본 스크린샷 카드. 새 디자인(07-01)은 전폭 히어로 대신
/// 가운데 놓인 134×179 카드로 이미지를 보여준다.
struct CardDetailImageSection: View {
    let card: Card
    let onOpenOriginal: () -> Void
    var onRemoteImageFailure: (URL) -> Void = { _ in }

    var body: some View {
        Button(action: onOpenOriginal) {
            RecapScreenshotThumbnail(
                category: card.category,
                assetName: card.detailImageAssetName,
                remoteURL: card.originalImageURL ?? card.thumbnailURL,
                cornerRadius: CardDetailStyle.cornerRadius,
                size: CardDetailStyle.detailImageSize,
                fallbackStyle: .folderCharacter,
                onRemoteLoadFailure: onRemoteImageFailure
            )
            .frame(
                width: CardDetailStyle.detailImageSize.width,
                height: CardDetailStyle.detailImageSize.height
            )
            .clipShape(
                RoundedRectangle(
                    cornerRadius: CardDetailStyle.cornerRadius,
                    style: .continuous
                )
            )
            .overlay {
                RoundedRectangle(
                    cornerRadius: CardDetailStyle.cornerRadius,
                    style: .continuous
                )
                .strokeBorder(Color.recapGray100, lineWidth: 0.5)
            }
            .overlay(alignment: .bottomTrailing) {
                CardExpandIcon()
                    .padding(10)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("원본 이미지 전체 보기")
    }
}

#if DEBUG
#Preview("정보카드 이미지") {
    CardDetailImageSection(
        card: Card(snapshot: SampleData.cards[1]),
        onOpenOriginal: {}
    )
}

#Preview("정보카드 이미지 - 폴백") {
    CardDetailImageSection(
        card: Card(snapshot: SampleData.cards[8]),
        onOpenOriginal: {}
    )
}
#endif
