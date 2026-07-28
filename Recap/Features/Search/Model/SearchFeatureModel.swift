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

    private var requestGeneration = 0
    private var activeQuery = ""
    private(set) var state: State
    private(set) var isLoadingNextPage = false

    init(
        loader: any SearchLoading,
        scope: SearchScope = .all,
        pageSize: Int = 20,
        initialState: State = .idle
    ) {
        self.loader = loader
        self.scope = scope
        self.pageSize = pageSize
        self.state = initialState
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
