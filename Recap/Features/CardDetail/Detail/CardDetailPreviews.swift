import SwiftUI

#if DEBUG
#Preview("즐겨찾기 완료") {
    NavigationStack {
        CardDetailView(
            card: SampleData.cards[1],
            initialToast: RecapToastContent(
                style: .success,
                message: "즐겨찾기에 추가했어요."
            )
        )
    }
    .environment(AppRouter())
    .environment(PreviewStores.cardStore())
}

#Preview("즐겨찾기 취소") {
    NavigationStack {
        CardDetailView(
            card: SampleData.cards[3],
            initialToast: RecapToastContent(
                style: .success,
                message: "즐겨찾기에서 삭제했어요."
            )
        )
    }
    .environment(AppRouter())
    .environment(PreviewStores.cardStore())
}

#Preview("원본 이미지 로딩 실패 - 전체") {
    NavigationStack {
        CardDetailView(
            card: SampleData.cards[1],
            imageState: .failedFullWidth
        )
    }
    .environment(AppRouter())
    .environment(PreviewStores.cardStore())
}

#Preview("원본 이미지 로딩 실패 - 카드") {
    NavigationStack {
        CardDetailView(
            card: SampleData.cards[1],
            imageState: .failedCard
        )
    }
    .environment(AppRouter())
    .environment(PreviewStores.cardStore())
}

#Preview("삭제 확인") {
    NavigationStack {
        CardDetailView(
            card: SampleData.cards[1],
            initiallyShowsDeleteConfirmation: true
        )
    }
    .environment(AppRouter())
    .environment(PreviewStores.cardStore())
}

#Preview("삭제 실패") {
    NavigationStack {
        CardDetailView(
            card: SampleData.cards[1],
            initialToast: RecapToastContent(
                style: .error,
                message: "스크린샷을 삭제하지 못했어요. 다시 시도해주세요."
            )
        )
    }
    .environment(AppRouter())
    .environment(PreviewStores.cardStore())
}
#endif
