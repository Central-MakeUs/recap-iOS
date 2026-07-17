import SwiftUI

struct HomeContainerView: View {
    @Environment(AppRouter.self) private var router
    @Environment(RecapCardStore.self) private var cardStore

    var body: some View {
        HomeView(
            status: .ready,
            recentCards: cardStore.recentCards,
            favoriteCards: cardStore.favoriteCards,
            collectionSummaries: cardStore.collectionSummaries,
            onAction: handleAction
        )
    }

    private func handleAction(_ action: HomeAction) {
        switch action {
        case .search:
            router.navigate(.search)
        case .startOrganizing:
            router.navigate(.cardCreationStart)
        case .openFavorites:
            router.selectedTab = .archive
        case .openAllRecent:
            router.navigate(.allRecentCards)
        case .openCard(let id):
            router.navigate(.cardDetail(id))
        case .openArchive(let kind):
            router.selectedTab = .archive
            router.navigate(.archiveDetail(kind), in: .archive)
        case .openSettings:
            router.navigate(.settings)
        }
    }
}

struct HomeView: View {
    var status: HomeStatus = .ready
    let recentCards: [InformationCard]
    let favoriteCards: [InformationCard]
    let collectionSummaries: [CollectionSummary]
    let onAction: (HomeAction) -> Void
    let onRetry: () -> Void

    init(
        status: HomeStatus = .ready,
        recentCards: [InformationCard],
        favoriteCards: [InformationCard] = [],
        collectionSummaries: [CollectionSummary],
        onAction: @escaping (HomeAction) -> Void,
        onRetry: @escaping () -> Void = {}
    ) {
        self.status = status
        self.recentCards = recentCards
        self.favoriteCards = favoriteCards
        self.collectionSummaries = collectionSummaries
        self.onAction = onAction
        self.onRetry = onRetry
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                HomeHeader(
                    openSettings: { onAction(.openSettings) },
                    openSearch: { onAction(.search) }
                )

                if status == .failed {
                    RecapLoadFailureView(style: .home, retry: onRetry)
                        .padding(.top, 131)
                } else {
                    HomeFavoritesSection(
                        cards: favoriteCards,
                        openFavorites: { onAction(.openFavorites) },
                        openCard: { onAction(.openCard($0)) }
                    )
                    .padding(.top, 26)

                    HomeRecentSection(
                        cards: recentCards,
                        openAllRecent: { onAction(.openAllRecent) },
                        openCard: { onAction(.openCard($0)) }
                    )
                    .padding(.top, 26)

                    HomeFrequentTypesSection(
                        summaries: collectionSummaries,
                        openArchive: { onAction(.openArchive($0)) }
                    )
                    .padding(.top, 26)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 15)
        }
        .background(Color.recapBackground)
        .toolbar(.hidden, for: .navigationBar)
    }
}

#Preview("Home with cards") {
    NavigationStack {
        HomeView(
            status: .ready,
            recentCards: SampleData.recentCards,
            favoriteCards: SampleData.cards.filter(\.isFavorite),
            collectionSummaries: SampleData.collectionSummaries,
            onAction: PreviewActions.handleHome
        )
    }
}

#Preview("Home partial") {
    NavigationStack {
        HomeView(
            status: .ready,
            recentCards: Array(SampleData.recentCards.prefix(2)),
            favoriteCards: Array(SampleData.cards.filter(\.isFavorite).prefix(2)),
            collectionSummaries: [],
            onAction: PreviewActions.handleHome
        )
    }
}

#Preview("Home empty") {
    NavigationStack {
        HomeView(
            status: .waiting,
            recentCards: [],
            favoriteCards: [],
            collectionSummaries: [],
            onAction: PreviewActions.handleHome
        )
    }
}

#Preview("Home loading failed") {
    NavigationStack {
        HomeView(
            status: .failed,
            recentCards: [],
            favoriteCards: [],
            collectionSummaries: [],
            onAction: PreviewActions.handleHome
        )
    }
}
