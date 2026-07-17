import SwiftUI

#Preview("보관함 홈 폴더형") {
    NavigationStack {
        CollectionHomeView(
            summaries: SampleData.collectionSummaries,
            favoriteCount: SampleData.cards.filter(\.isFavorite).count,
            otherCount: SampleData.cards(in: .other).count,
            onAction: PreviewActions.handleArchive
        )
    }
}

#Preview("보관함 홈 리스트형") {
    NavigationStack {
        CollectionHomeView(
            summaries: SampleData.collectionSummaries,
            favoriteCount: SampleData.cards.filter(\.isFavorite).count,
            otherCount: SampleData.cards(in: .other).count,
            layoutMode: .list,
            onAction: PreviewActions.handleArchive
        )
    }
}

#Preview("보관함 항목 없음") {
    NavigationStack {
        CollectionHomeView(
            summaries: [],
            favoriteCount: 0,
            onAction: PreviewActions.handleArchive
        )
    }
}

#Preview("보관함 리스트 로딩 실패") {
    NavigationStack {
        CollectionHomeView(
            summaries: [],
            favoriteCount: 0,
            loadState: .failed,
            onAction: PreviewActions.handleArchive
        )
    }
}
