import SwiftUI
#Preview("Archive type") {
    NavigationStack {
        CollectionHomeView(
            summaries: SampleData.collectionSummaries,
            onAction: PreviewActions.handleArchive
        )
    }
}

#Preview("Archive favorites list") {
    NavigationStack {
        CollectionHomeView(
            summaries: SampleData.collectionSummaries,
            favoriteCards: SampleData.cards.filter(\.isFavorite),
            initialSegment: .favorites,
            onAction: PreviewActions.handleArchive
        )
    }
}

#Preview("Archive favorites empty") {
    NavigationStack {
        CollectionHomeView(
            summaries: SampleData.collectionSummaries,
            favoriteCards: [],
            initialSegment: .favorites,
            onAction: PreviewActions.handleArchive
        )
    }
}

#Preview("Archive other empty") {
    NavigationStack {
        CollectionHomeView(
            summaries: SampleData.collectionSummaries,
            otherCards: [],
            initialSegment: .other,
            onAction: PreviewActions.handleArchive
        )
    }
}
