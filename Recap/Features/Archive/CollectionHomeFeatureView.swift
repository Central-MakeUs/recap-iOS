import SwiftUI

struct CollectionHomeContainerView: View {
    @Environment(AppRouter.self) private var router
    @Environment(RecapCardStore.self) private var cardStore

    var body: some View {
        CollectionHomeView(
            summaries: cardStore.collectionSummaries,
            favoriteCards: cardStore.favoriteCards,
            otherCards: cardStore.uncategorizedCards,
            onAction: handleAction
        )
    }

    private func handleAction(_ action: ArchiveAction) {
        switch action {
        case .search:
            router.navigate(.search)
        case .openArchive(let kind):
            router.navigate(.archiveDetail(kind))
        case .openCard(let id):
            router.navigate(.cardDetail(id))
        case .selectFilter:
            break
        case .deleteCards:
            break
        case .openSettings:
            router.navigate(.settings)
        }
    }
}

struct CollectionHomeView: View {
    enum LayoutMode {
        case grid
        case list
    }

    enum Segment: String, CaseIterable, Identifiable {
        case favorites = "즐겨찾기"
        case type = "유형별 보기"
        case other = "기타"

        var id: String { rawValue }
    }

    @State private var segment: Segment = .type
    @State private var layoutMode: LayoutMode = .grid

    let summaries: [CollectionSummary]
    let favoriteCards: [InformationCard]
    let otherCards: [InformationCard]
    let onAction: (ArchiveAction) -> Void

    init(
        summaries: [CollectionSummary],
        favoriteCards: [InformationCard] = SampleData.cards.filter(\.isFavorite),
        otherCards: [InformationCard] = [],
        initialSegment: Segment = .type,
        onAction: @escaping (ArchiveAction) -> Void
    ) {
        self.summaries = summaries
        self.favoriteCards = favoriteCards
        self.otherCards = otherCards
        self.onAction = onAction
        _segment = State(initialValue: initialSegment)
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                CollectionHomeHeader(segment: segment, layoutMode: $layoutMode)

                Button(action: openSearch) {
                    SearchBarDisplay()
                }
                .buttonStyle(.plain)
                .padding(.top, 25)

                CollectionHomeSegmentControl(selection: $segment)
                    .padding(.top, 19)

                content
                    .padding(.top, 20)
            }
            .padding(.horizontal, 16)
            .padding(.top, 15)
            .padding(.bottom, 122)
        }
        .background(Color.recapBackground)
        .toolbar(.hidden, for: .navigationBar)
    }

    @ViewBuilder
    private var content: some View {
        switch segment {
        case .type:
            if layoutMode == .grid {
                CollectionHomeTypeGrid(
                    summaries: summaries,
                    onOpenArchive: openArchive
                )
            } else {
                CollectionHomeTypeList(
                    summaries: summaries,
                    onOpenArchive: openArchive
                )
            }
        case .favorites:
            CollectionHomeCardSection(
                cards: favoriteCards,
                style: .favorites,
                emptySegment: segment,
                onSelectFilter: selectFilter,
                onOpenCard: openCard
            )
        case .other:
            CollectionHomeCardSection(
                cards: otherCards,
                style: .other,
                emptySegment: segment,
                onSelectFilter: selectFilter,
                onOpenCard: openCard
            )
        }
    }

    private func openSearch() { onAction(.search) }
    private func openArchive(_ kind: CollectionKind) { onAction(.openArchive(kind)) }
    private func openCard(_ id: InformationCard.ID) { onAction(.openCard(id)) }
    private func selectFilter(_ title: String) { onAction(.selectFilter(title)) }
}
