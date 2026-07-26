import SwiftUI

struct SearchResultsView: View {
    enum ScreenMode: Hashable {
        case normal
        case failureBlank
        case targetCardEmpty
    }

    @Environment(\.dismiss) private var dismiss
    @State private var query: String

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
                SearchIncompleteState(title: "미구현: 검색 실패")
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
    }

    private var normalContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 22) {
                if query.isEmpty {
                    SearchRecentContent(
                        recentKeywords: recentSearchStore.keywords,
                        clearKeywords: recentSearchStore.removeAll,
                        selectKeyword: selectRecentKeyword
                    )
                } else {
                    searchStateContent
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 18)
            .padding(.bottom, 40)
        }
    }

    private func selectRecentKeyword(_ keyword: String) {
        recentSearchStore.record(keyword)
        query = keyword
    }

    private func saveCurrentQuery() {
        recentSearchStore.record(query)
    }

    @ViewBuilder
    private var searchStateContent: some View {
        switch model.state {
        case .idle, .loading:
            Color.clear
        case .failed:
            SearchIncompleteState(title: "미구현: 검색 실패")
        case .loaded(let content) where content.results.isEmpty:
            SearchIncompleteState(title: "미구현: 검색 결과 없음")
        case .loaded(let content):
            SearchResultsList(
                totalCount: content.totalCount,
                results: content.results,
                openCard: openCard,
                loadNextPageIfNeeded: loadNextPageIfNeeded
            )
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

#Preview("Search empty - incomplete") {
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
