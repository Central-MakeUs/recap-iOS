import Foundation
import Observation

@MainActor
@Observable
final class SearchFeatureModel {
    enum State: Equatable {
        case idle
        case loading
        case loaded(SearchContent)
        case failed
    }

    private let loader: any SearchLoading
    private let scope: SearchScope
    private let pageSize: Int
    /// 결과가 실릴 때마다 스냅샷을 정식 `Card`로 승격한다. 행이 스토어에서
    /// 읽으므로 여기서 넣어줘야 화면에 보인다. 테스트는 넘기지 않아도 된다.
    private let cardStore: CardStore?

    private var requestGeneration = 0
    private var activeQuery = ""
    private(set) var state: State {
        didSet { upsertLoadedCards() }
    }
    private(set) var isLoadingNextPage = false

    init(
        loader: any SearchLoading,
        scope: SearchScope = .all,
        pageSize: Int = 20,
        initialState: State = .idle,
        cardStore: CardStore? = nil
    ) {
        self.loader = loader
        self.scope = scope
        self.pageSize = pageSize
        self.state = initialState
        self.cardStore = cardStore
        upsertLoadedCards()   // didSet은 초기화 대입에는 불리지 않는다
    }

    private func upsertLoadedCards() {
        guard case .loaded(let content) = state else { return }
        cardStore?.upsert(content.results.map(\.card))
    }

    func search(
        query rawQuery: String,
        debounce: Duration = .milliseconds(350)
    ) async {
        let query = Self.normalizedQuery(rawQuery)
        requestGeneration += 1
        let generation = requestGeneration

        guard !query.isEmpty else {
            activeQuery = ""
            state = .idle
            isLoadingNextPage = false
            return
        }

        guard query.count <= 100 else {
            activeQuery = query
            state = .failed
            return
        }

        if case .loaded(let content) = state, content.query == query {
            return
        }

        activeQuery = query

        do {
            try await Task.sleep(for: debounce)
            try Task.checkCancellation()
            guard generation == requestGeneration else { return }
            try await loadFirstPage(query: query, generation: generation)
        } catch is CancellationError {
            return
        } catch {
            guard generation == requestGeneration else { return }
            state = .failed
        }
    }

    func retry() async {
        guard !activeQuery.isEmpty, activeQuery.count <= 100 else { return }

        requestGeneration += 1
        let generation = requestGeneration

        do {
            try await loadFirstPage(query: activeQuery, generation: generation)
        } catch is CancellationError {
            return
        } catch {
            guard generation == requestGeneration else { return }
            state = .failed
        }
    }

    func refreshCurrentQuery() async {
        guard !activeQuery.isEmpty, activeQuery.count <= 100 else { return }

        requestGeneration += 1
        let generation = requestGeneration
        let previousState = state

        do {
            try await loadFirstPage(query: activeQuery, generation: generation)
        } catch is CancellationError {
            return
        } catch {
            guard generation == requestGeneration else { return }
            state = previousState
        }
    }

    func loadNextPageIfNeeded(after resultID: SearchResult.ID) async {
        guard
            case .loaded(let content) = state,
            content.results.last?.id == resultID,
            content.hasNext,
            !isLoadingNextPage
        else {
            return
        }

        isLoadingNextPage = true
        let generation = requestGeneration

        defer {
            if generation == requestGeneration {
                isLoadingNextPage = false
            }
        }

        do {
            let page = try await loader.search(
                query: content.query,
                scope: scope,
                page: content.nextPage,
                size: pageSize
            )
            try Task.checkCancellation()
            guard
                generation == requestGeneration,
                case .loaded(let current) = state,
                current.query == content.query,
                current.nextPage == content.nextPage
            else {
                return
            }

            let existingCaptureIDs = Set(current.results.map(\.captureID))
            let newResults = page.items.filter {
                !existingCaptureIDs.contains($0.captureID)
            }
            state = .loaded(
                SearchContent(
                    query: current.query,
                    totalCount: page.count,
                    hasNext: page.hasNext,
                    nextPage: current.nextPage + 1,
                    results: current.results + newResults
                )
            )
        } catch is CancellationError {
            return
        } catch {
            return
        }
    }

    private func loadFirstPage(
        query: String,
        generation: Int
    ) async throws {
        state = .loading
        isLoadingNextPage = false

        let page = try await loader.search(
            query: query,
            scope: scope,
            page: 0,
            size: pageSize
        )
        try Task.checkCancellation()
        guard generation == requestGeneration else { return }

        state = .loaded(
            SearchContent(
                query: query,
                totalCount: page.count,
                hasNext: page.hasNext,
                nextPage: 1,
                results: page.items
            )
        )
    }

    nonisolated static func normalizedQuery(_ query: String) -> String {
        query
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
    }
}
