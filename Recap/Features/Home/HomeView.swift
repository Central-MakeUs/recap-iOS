import SwiftUI

struct HomeContainerView: View {
    @Environment(AppRouter.self) private var router
    @Environment(CardStore.self) private var cardStore

    @State private var model: HomeFeatureModel
    @State private var hasRequestedSummary = false
    let invalidationCenter: CardDataInvalidationCenter

    init(
        summaryLoader: any HomeSummaryLoading,
        cardStore: CardStore,
        invalidationCenter: CardDataInvalidationCenter
    ) {
        self.invalidationCenter = invalidationCenter
        _model = State(
            initialValue: HomeFeatureModel(
                summaryLoader: summaryLoader,
                cardStore: cardStore
            )
        )
    }

    var body: some View {
        HomeView(
            status: homeStatus,
            recentCards: cards(for: content.recentCards),
            favoriteCards: cards(for: content.favoriteCards),
            collectionSummaries: content.frequentTypes,
            onAction: handleAction,
            onRetry: retry
        )
        .task(id: reloadTrigger) {
            guard reloadTrigger.isActive else { return }

            if hasRequestedSummary {
                await model.reload()
            } else {
                await model.loadIfNeeded()
            }
            guard !Task.isCancelled else { return }
            hasRequestedSummary = true
        }
    }

    private var reloadTrigger: HomeReloadTrigger {
        HomeReloadTrigger(
            revision: invalidationCenter.homeRevision,
            isActive: router.selectedTab == .home && router.path(for: .home).isEmpty
        )
    }

    private var content: HomeSummaryContent {
        guard case .loaded(let content) = model.state else {
            return .empty
        }
        return content
    }

    /// 응답은 순서·소속만 정하고, 그리기는 스토어의 공유 인스턴스로 한다.
    /// 모델이 적재 시점에 upsert하므로 스토어 조회는 실패하지 않는다.
    private func cards(for snapshots: [InformationCard]) -> [Card] {
        snapshots.compactMap { cardStore.card(withCaptureID: $0.captureID) }
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
            router.navigate(.archiveFavorites)
        case .openAllRecent:
            router.navigate(.allRecentCards)
        case .openCard(let captureID):
            router.navigate(.remoteCardDetail(captureID))
        case .openArchive(let kind):
            router.navigate(.archiveDetail(kind))
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

private struct HomeReloadTrigger: Hashable {
    let revision: Int
    let isActive: Bool
}

struct HomeView: View {
    var status: HomeStatus = .ready
    let recentCards: [Card]
    let favoriteCards: [Card]
    let collectionSummaries: [CollectionSummary]
    let onAction: (HomeAction) -> Void
    let onRetry: () -> Void

    init(
        status: HomeStatus = .ready,
        recentCards: [Card],
        favoriteCards: [Card] = [],
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
        VStack(alignment: .leading, spacing: 0) {
            // Figma 02-01의 "스크롤 Fixed 영역": 헤더는 스크롤과 무관하게 고정된다.
            HomeHeader(
                openSettings: { onAction(.openSettings) },
                openSearch: { onAction(.search) }
            )
            .padding(.horizontal, 16)
            .padding(.top, 15)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
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
                            openCard: { onAction(.openCard($0.captureID)) }
                        )
                        .padding(.top, 26)

                        HomeRecentSection(
                            cards: recentCards,
                            openAllRecent: { onAction(.openAllRecent) },
                            openCard: { onAction(.openCard($0.captureID)) }
                        )
                        .padding(.top, 26)

                        HomeFrequentTypesSection(
                            summaries: collectionSummaries,
                            openArchive: { onAction(.openArchive($0)) }
                        )
                        .padding(.top, 26)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
            }
        }
        .background(Color.recapBackground)
        .toolbar(.hidden, for: .navigationBar)
        .interactivePopGestureEnabled()
    }
}

#if DEBUG
#Preview("Home with cards") {
    NavigationStack {
        HomeView(
            status: .ready,
            recentCards: SampleData.recentCards.compactMap(Card.init(snapshot:)),
            favoriteCards: SampleData.cards.filter(\.isFavorite).compactMap(Card.init(snapshot:)),
            collectionSummaries: SampleData.collectionSummaries,
            onAction: PreviewActions.handleHome
        )
    }
}

#Preview("Home partial") {
    NavigationStack {
        HomeView(
            status: .ready,
            recentCards: Array(SampleData.recentCards.prefix(2)).compactMap(Card.init(snapshot:)),
            favoriteCards: Array(SampleData.cards.filter(\.isFavorite).prefix(2)).compactMap(Card.init(snapshot:)),
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
#endif
