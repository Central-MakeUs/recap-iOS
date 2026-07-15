import SwiftUI

#Preview("즐겨찾기 완료") {
    NavigationStack {
        CardDetailView(
            card: SampleData.cards[1],
            initialOverlay: .favoriteToast
        )
    }
    .environment(AppRouter())
    .environment(PreviewStores.recapCardStore())
}

#Preview("원본 이미지 로딩 실패 - 전체") {
    NavigationStack {
        CardDetailView(
            card: SampleData.cards[1],
            imageState: .failedFullWidth
        )
    }
    .environment(AppRouter())
    .environment(PreviewStores.recapCardStore())
}

#Preview("원본 이미지 로딩 실패 - 카드") {
    NavigationStack {
        CardDetailView(
            card: SampleData.cards[1],
            imageState: .failedCard
        )
    }
    .environment(AppRouter())
    .environment(PreviewStores.recapCardStore())
}

#Preview("삭제 확인") {
    NavigationStack {
        CardDetailView(
            card: SampleData.cards[1],
            initialOverlay: .deleteConfirmation
        )
    }
    .environment(AppRouter())
    .environment(PreviewStores.recapCardStore())
}

#Preview("삭제 실패") {
    NavigationStack {
        CardDetailView(
            card: SampleData.cards[1],
            initialOverlay: .deleteFailure
        )
    }
    .environment(AppRouter())
    .environment(PreviewStores.recapCardStore())
}
