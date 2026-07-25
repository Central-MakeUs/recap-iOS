import SwiftUI

struct SearchResultsView: View {
    enum ScreenMode: Hashable {
        case normal
        case failureBlank
        case targetCardEmpty
    }

    @Environment(\.dismiss) private var dismiss
    @State private var query: String
    @State private var recentKeywords: [String]

    let mode: ScreenMode
    let model: SearchFeatureModel
    let onAction: (SearchAction) -> Void

    init(
        initialQuery: String = "",
        recentKeywords: [String] = ["검색어", "검색어 01234", "검색검색검색", "검색어검색어"],
        mode: ScreenMode = .normal,
        model: SearchFeatureModel,
        onAction: @escaping (SearchAction) -> Void
    ) {
        _query = State(initialValue: initialQuery)
        _recentKeywords = State(initialValue: recentKeywords)
        self.mode = mode
        self.model = model
        self.onAction = onAction
    }

    var body: some View {
        VStack(spacing: 0) {
            SearchTopBar(query: $query, onClose: close)

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
                        recentKeywords: $recentKeywords,
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
        query = keyword == "검색어 01234" ? "숙소예약" : keyword
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
            onAction: PreviewActions.handleSearch
        )
    }
}

#Preview("Search home - no recent terms") {
    NavigationStack {
        SearchResultsView(
            recentKeywords: [],
            model: previewSearchModel(),
            onAction: PreviewActions.handleSearch
        )
    }
}

#Preview("Search results") {
    NavigationStack {
        SearchResultsView(
            initialQuery: "숙소예약",
            model: previewSearchModel(query: "숙소예약"),
            onAction: PreviewActions.handleSearch
        )
    }
}

#Preview("Search empty - incomplete") {
    NavigationStack {
        SearchResultsView(
            initialQuery: "없는검색어",
            model: previewSearchModel(query: "없는검색어"),
            onAction: PreviewActions.handleSearch
        )
    }
}

#Preview("Search failure - incomplete") {
    NavigationStack {
        SearchResultsView(
            mode: .failureBlank,
            model: previewSearchModel(state: .failed),
            onAction: PreviewActions.handleSearch
        )
    }
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
