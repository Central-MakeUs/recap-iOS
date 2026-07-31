import SwiftUI

struct SearchResultsView: View {
    enum ScreenMode: Hashable {
        case normal
        case failureBlank
        case targetCardEmpty
    }

    @Environment(\.dismiss) private var dismiss
    @State private var query: String
    @State private var favoriteUpdatingIDs: Set<InformationCard.ID> = []
    @State private var toast: RecapToastContent?

    let mode: ScreenMode
    let model: SearchFeatureModel
    let recentSearchStore: RecentSearchStore
    let onAction: (SearchAction) -> Void

    init(
        initialQuery: String = "",
        mode: ScreenMode = .normal,
        model: SearchFeatureModel,
        recentSearchStore: RecentSearchStore,
        onAction: @escaping (SearchAction) -> Void
    ) {
        _query = State(initialValue: initialQuery)
        self.mode = mode
        self.model = model
        self.recentSearchStore = recentSearchStore
        self.onAction = onAction
    }

    var body: some View {
        VStack(spacing: 0) {
            SearchTopBar(
                query: $query,
                onSubmit: saveCurrentQuery,
                onClose: close
            )

            switch mode {
            case .normal:
                normalContent
            case .failureBlank:
                SearchFailureView(onRetry: retrySearch)
            case .targetCardEmpty:
                SearchTargetCardEmptyState()
            }
        }
        .background(Color.recapBackground)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .task(id: query) {
            guard mode == .normal else { return }
            await model.search(query: query)
        }
        .recapToast(toast)
        .task(id: toast) {
            guard toast != nil else { return }
            try? await Task.sleep(for: .seconds(2))
            guard !Task.isCancelled else { return }
            toast = nil
        }
    }

    private func toggleFavorite(_ id: InformationCard.ID) {
        guard favoriteUpdatingIDs.insert(id).inserted else { return }

        Task {
            defer { favoriteUpdatingIDs.remove(id) }

            do {
                let isFavorite = try await model.toggleFavorite(cardID: id)
                toast = RecapToastContent(
                    style: .success,
                    message: isFavorite
                        ? "즐겨찾기에 추가했어요."
                        : "즐겨찾기에서 해제했어요."
                )
            } catch {
                toast = RecapToastContent(
                    style: .error,
                    message: "즐겨찾기를 변경하지 못했어요. 다시 시도해주세요."
                )
            }
        }
    }

    @ViewBuilder
    private var normalContent: some View {
        if query.isEmpty {
            scrollContent {
                SearchRecentContent(
                    recentKeywords: recentSearchStore.keywords,
                    clearKeywords: recentSearchStore.removeAll,
                    selectKeyword: selectRecentKeyword,
                    removeKeyword: recentSearchStore.remove
                )
            }
        } else {
            searchStateContent
        }
    }

    private func selectRecentKeyword(_ keyword: String) {
        recentSearchStore.record(keyword)
        query = keyword
    }

    private func saveCurrentQuery() {
        recentSearchStore.record(query)
    }

    private func retrySearch() {
        Task {
            await model.retry()
        }
    }

    @ViewBuilder
    private var searchStateContent: some View {
        switch model.state {
        case .idle, .loading:
            Color.clear
        case .failed:
            SearchFailureView(onRetry: retrySearch)
        case .loaded(let content) where content.results.isEmpty:
            SearchNoResultsView()
        case .loaded(let content):
            scrollContent {
                SearchResultsList(
                    totalCount: content.totalCount,
                    results: content.results,
                    openCard: openCard,
                    loadNextPageIfNeeded: loadNextPageIfNeeded,
                    onToggleFavorite: toggleFavorite,
                    favoriteUpdatingIDs: favoriteUpdatingIDs
                )
            }
        }
    }

    private func scrollContent<Content: View>(
        @ViewBuilder content: () -> Content
    ) -> some View {
        ScrollView(showsIndicators: false) {
            content()
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.top, 18)
                .padding(.bottom, 40)
        }
    }

    private func close() { dismiss() }
    private func openCard(_ id: InformationCard.ID) {
        guard
            case .loaded(let content) = model.state,
            let card = content.results.first(where: { $0.card.id == id })?.card
        else {
            return
        }
        onAction(.openCard(card))
    }

    private func loadNextPageIfNeeded(_ resultID: SearchResult.ID) {
        Task {
            await model.loadNextPageIfNeeded(after: resultID)
        }
    }
}

#Preview("Search home - recent terms") {
    NavigationStack {
        SearchResultsView(
            model: previewSearchModel(),
            recentSearchStore: previewRecentSearchStore(),
            onAction: PreviewActions.handleSearch
        )
    }
}

#Preview("Search home - no recent terms") {
    NavigationStack {
        SearchResultsView(
            model: previewSearchModel(),
            recentSearchStore: previewRecentSearchStore(keywords: []),
            onAction: PreviewActions.handleSearch
        )
    }
}

#Preview("Search results") {
    NavigationStack {
        SearchResultsView(
            initialQuery: "숙소예약",
            model: previewSearchModel(query: "숙소예약"),
            recentSearchStore: previewRecentSearchStore(),
            onAction: PreviewActions.handleSearch
        )
    }
}

#Preview("Search empty") {
    NavigationStack {
        SearchResultsView(
            initialQuery: "없는검색어",
            model: previewSearchModel(query: "없는검색어"),
            recentSearchStore: previewRecentSearchStore(),
            onAction: PreviewActions.handleSearch
        )
    }
}

#Preview("Search failure - incomplete") {
    NavigationStack {
        SearchResultsView(
            mode: .failureBlank,
            model: previewSearchModel(state: .failed),
            recentSearchStore: previewRecentSearchStore(),
            onAction: PreviewActions.handleSearch
        )
    }
}

@MainActor
private func previewRecentSearchStore(
    keywords: [String] = ["검색어", "검색어 01234", "검색검색검색", "검색어검색어"]
) -> RecentSearchStore {
    RecentSearchStore(
        persistence: InMemoryRecentSearchPersistence(keywords: keywords)
    )
}

@MainActor
private func previewSearchModel(
    query: String = "",
    state: SearchFeatureModel.State? = nil
) -> SearchFeatureModel {
    let cards = SampleData.search(query)
    let initialState = state ?? (
        query.isEmpty
            ? .idle
            : .loaded(
                SearchContent(
                    query: query,
                    totalCount: cards.count,
                    hasNext: false,
                    nextPage: 1,
                    results: cards.map(SearchResult.init(card:))
                )
            )
    )

    return SearchFeatureModel(
        loader: PreviewSearchLoader(),
        initialState: initialState
    )
}
