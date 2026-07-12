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
    let search: (String) -> [InformationCard]
    let onAction: (SearchAction) -> Void

    init(
        initialQuery: String = "",
        recentKeywords: [String] = ["검색어", "검색어 01234", "검색검색검색", "검색어검색어"],
        mode: ScreenMode = .normal,
        search: @escaping (String) -> [InformationCard],
        onAction: @escaping (SearchAction) -> Void
    ) {
        _query = State(initialValue: initialQuery)
        _recentKeywords = State(initialValue: recentKeywords)
        self.mode = mode
        self.search = search
        self.onAction = onAction
    }

    private var results: [InformationCard] {
        search(query)
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
        .background(RecapTheme.ColorToken.background)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }

    private var normalContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 22) {
                if query.isEmpty {
                    SearchRecentContent(
                        recentKeywords: $recentKeywords,
                        selectKeyword: selectRecentKeyword
                    )
                } else if results.isEmpty {
                    SearchIncompleteState(title: "미구현: 검색 결과 없음")
                } else {
                    SearchResultsList(results: results, openCard: openCard)
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

    private func close() { dismiss() }
    private func openCard(_ id: InformationCard.ID) { onAction(.openCard(id)) }
}

#Preview("Search home - recent terms") {
    NavigationStack {
        SearchResultsView(
            search: SampleData.search,
            onAction: PreviewActions.handleSearch
        )
    }
}

#Preview("Search home - no recent terms") {
    NavigationStack {
        SearchResultsView(
            recentKeywords: [],
            search: SampleData.search,
            onAction: PreviewActions.handleSearch
        )
    }
}

#Preview("Search results") {
    NavigationStack {
        SearchResultsView(
            initialQuery: "숙소예약",
            search: SampleData.search,
            onAction: PreviewActions.handleSearch
        )
    }
}

#Preview("Search empty - incomplete") {
    NavigationStack {
        SearchResultsView(
            initialQuery: "없는검색어",
            search: SampleData.search,
            onAction: PreviewActions.handleSearch
        )
    }
}

#Preview("Search failure - incomplete") {
    NavigationStack {
        SearchResultsView(
            mode: .failureBlank,
            search: SampleData.search,
            onAction: PreviewActions.handleSearch
        )
    }
}
