import SwiftUI
#Preview("Archive type") {
    @Previewable @State var segment = ArchiveSection.type

    NavigationStack {
        CollectionHomeView(
            segment: $segment,
            summaries: SampleData.collectionSummaries,
            onAction: PreviewActions.handleArchive
        )
    }
}

#Preview("Archive favorites list") {
    @Previewable @State var segment = ArchiveSection.favorites

    NavigationStack {
        CollectionHomeView(
            segment: $segment,
            summaries: SampleData.collectionSummaries,
            favoriteCards: SampleData.cards.filter(\.isFavorite),
            onAction: PreviewActions.handleArchive
        )
    }
}

#Preview("Archive favorites empty") {
    @Previewable @State var segment = ArchiveSection.favorites

    NavigationStack {
        CollectionHomeView(
            segment: $segment,
            summaries: SampleData.collectionSummaries,
            favoriteCards: [],
            onAction: PreviewActions.handleArchive
        )
    }
}

#Preview("Archive other empty") {
    @Previewable @State var segment = ArchiveSection.other

    NavigationStack {
        CollectionHomeView(
            segment: $segment,
            summaries: SampleData.collectionSummaries,
            otherCards: [],
            onAction: PreviewActions.handleArchive
        )
    }
}
