import Observation

@MainActor
@Observable
final class ArchiveHomeFeatureModel {
    enum State: Equatable {
        case idle
        case loading
        case loaded(ArchiveHomeContent)
        case failed
    }

    private let loader: any ArchiveLoading
    private(set) var state: State = .idle

    init(loader: any ArchiveLoading) {
        self.loader = loader
    }

    func loadIfNeeded() async {
        guard state == .idle else { return }
        await load()
    }

    func retry() async {
        await load()
    }

    private func load() async {
        state = .loading

        do {
            state = .loaded(try await loader.fetchHome())
        } catch is CancellationError {
            state = .idle
        } catch {
            state = .failed
        }
    }
}

@MainActor
@Observable
final class ArchiveDetailFeatureModel {
    enum State: Equatable {
        case idle
        case loading
        case loaded([InformationCard])
        case failed
    }

    let scope: ArchiveDetailScope

    private let loader: any ArchiveLoading
    private(set) var state: State = .idle
    private(set) var sort: ArchiveSort = .latest

    init(
        scope: ArchiveDetailScope,
        loader: any ArchiveLoading
    ) {
        self.scope = scope
        self.loader = loader
    }

    func loadIfNeeded() async {
        guard state == .idle else { return }
        await load()
    }

    func retry() async {
        await load()
    }

    func selectSort(_ sort: ArchiveSort) async {
        guard scope != .favorites, self.sort != sort else { return }
        self.sort = sort
        await load()
    }

    private func load() async {
        state = .loading

        do {
            state = .loaded(
                try await loader.fetchCards(scope: scope, sort: sort)
            )
        } catch is CancellationError {
            state = .idle
        } catch {
            state = .failed
        }
    }
}
