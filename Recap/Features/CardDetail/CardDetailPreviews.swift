import SwiftUI

#Preview("즐겨찾기 완료") {
    CardDetailView(
        card: SampleData.cards[1],
        initialOverlay: .favoriteToast,
        onAction: PreviewActions.handleCardDetail
    )
}

#Preview("원본 이미지 로딩 실패 - 전체") {
    CardDetailView(
        card: SampleData.cards[1],
        imageState: .failedFullWidth,
        onAction: PreviewActions.handleCardDetail
    )
}

#Preview("원본 이미지 로딩 실패 - 카드") {
    CardDetailView(
        card: SampleData.cards[1],
        imageState: .failedCard,
        onAction: PreviewActions.handleCardDetail
    )
}

#Preview("삭제 확인") {
    CardDetailView(
        card: SampleData.cards[1],
        initialOverlay: .deleteConfirmation,
        onAction: PreviewActions.handleCardDetail
    )
}

#Preview("삭제 실패") {
    CardDetailView(
        card: SampleData.cards[1],
        initialOverlay: .deleteFailure,
        onAction: PreviewActions.handleCardDetail
    )
}
