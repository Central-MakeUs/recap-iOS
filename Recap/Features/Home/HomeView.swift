import SwiftUI

struct HomeContainerView: View {
    @Environment(AppRouter.self) private var router

    @State private var model: HomeFeatureModel

    init(summaryLoader: any HomeSummaryLoading) {
        _model = State(initialValue: HomeFeatureModel(summaryLoader: summaryLoader))
    }

    var body: some View {
        HomeView(
            status: homeStatus,
            recentCards: content.recentCards,
            favoriteCards: content.favoriteCards,
            collectionSummaries: content.frequentTypes,
            onAction: handleAction,
            onRetry: retry
        )
        .task {
            await model.loadIfNeeded()
        }
    }

    private var content: HomeSummaryContent {
        guard case .loaded(let content) = model.state else {
            return .empty
        }
        return content
    }

    private var homeStatus: HomeStatus {
        switch model.state {
        case .idle, .loading:
            .loading
        case .loaded(let content):
            content.hasAnyCapture ? .ready : .waiting
        case .failed:
            .failed
        }
    }

    private func handleAction(_ action: HomeAction) {
        switch action {
        case .search:
            router.navigate(.search)
        case .startOrganizing:
            router.navigate(.cardCreationStart)
        case .openFavorites:
            router.openArchive(section: .favorites)
        case .openAllRecent:
            router.navigate(.allRecentCards)
        case .openCard(let card):
            router.navigate(.homeCardDetail(card))
        case .openArchive(let kind):
            router.openArchive()
            router.navigate(.archiveDetail(kind), in: .archive)
        case .openSettings:
            router.navigate(.settings)
        }
    }

    private func retry() {
        Task {
            await model.retry()
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

                if status == .loading {
                    ProgressView()
                        .tint(Color.recapBlue300)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 131)
                } else if status == .failed {
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

#Preview("Home loading") {
    NavigationStack {
        HomeView(
            status: .loading,
            recentCards: [],
            favoriteCards: [],
            collectionSummaries: [],
            onAction: PreviewActions.handleHome
        )
    }
}
