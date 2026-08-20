import SwiftUI

struct SearchResultsView: View {
    enum ScreenMode: Hashable {
        case normal
        case failureBlank
        case targetCardEmpty
    }

    @Environment(\.dismiss) private var dismiss
    @Environment(CardStore.self) private var cardStore
    @State private var query: String
    @State private var toast: RecapToastContent?
    @State private var cardPendingDeletion: Card?

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
        .interactivePopGestureEnabled()
        .task(id: query) {
            guard mode == .normal else { return }
            await model.search(query: query)
        }
        .recapConfirmationDialog(
            isPresented: Binding(
                get: { cardPendingDeletion != nil },
                set: { if !$0 { cardPendingDeletion = nil } }
            ),
            title: "스크린샷을 삭제할까요?",
            message: "삭제한 스크린샷 정보는\n되돌릴 수 없어요.",
            cancelTitle: "취소",
            confirmTitle: "삭제",
            // 다이얼로그가 확인 직전에 isPresented를 내리면서 카드가 비워지므로,
            // 그리는 시점의 카드를 클로저에 담아둔다.
            onConfirm: { [card = cardPendingDeletion] in
                guard let card else { return }
                delete(card)
            }
        )
        .recapToast(toast)
        .task(id: toast) {
            guard toast != nil else { return }
            try? await Task.sleep(for: .seconds(2))
            guard !Task.isCancelled else { return }
            toast = nil
        }
    }

    private func toggleFavorite(_ card: Card) {
        Task {
            guard let content = await cardStore.toggleFavoriteReturningToast(card) else { return }
            toast = content
        }
    }

    /// 삭제는 상세 화면과 같은 길로 보낸다. 스토어가 내리면 홈·보관함도 함께 갱신된다.
    private func delete(_ card: Card) {
        Task {
            do {
                try await cardStore.delete(card)
                await model.refreshCurrentQuery()
            } catch {
                toast = RecapToastMessage.screenshotDeleteFailed.content
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
            SearchResultsList(
                totalCount: content.totalCount,
                results: content.results,
                openCard: openCard,
                loadNextPageIfNeeded: loadNextPageIfNeeded,
                onToggleFavorite: toggleFavorite,
                onEditCard: { onAction(.editCard($0.captureID)) },
                onRequestDeletion: { cardPendingDeletion = $0 }
            )
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
    private func openCard(_ captureID: Int64) {
        onAction(.openCard(captureID))
    }

    private func loadNextPageIfNeeded(_ resultID: SearchResult.ID) {
        Task {
            await model.loadNextPageIfNeeded(after: resultID)
        }
    }
}

#if DEBUG
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
#endif

@MainActor
private func previewRecentSearchStore(
    keywords: [String] = ["검색어", "검색어 01234", "검색검색검색", "검색어검색어"]
) -> RecentSearchStore {
    RecentSearchStore(
        persistence: InMemoryRecentSearchPersistence(keywords: keywords)
    )
}

#if DEBUG
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
#endif
