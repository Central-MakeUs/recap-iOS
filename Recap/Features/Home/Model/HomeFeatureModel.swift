import Observation

@MainActor
@Observable
final class HomeFeatureModel {
    enum State: Equatable {
        case idle
        case loading
        case loaded(HomeSummaryContent)
        case failed
    }

    private let summaryLoader: any HomeSummaryLoading

    private(set) var state: State = .idle

    init(summaryLoader: any HomeSummaryLoading) {
        self.summaryLoader = summaryLoader
    }

    func loadIfNeeded() async {
        guard state == .idle else { return }
        await load()
    }

    func retry() async {
        await load()
    }

    func reload() async {
        await load()
    }

    private func load() async {
        state = .loading

        do {
            state = .loaded(try await summaryLoader.fetchSummary())
        } catch is CancellationError {
            state = .idle
        } catch {
            state = .failed
        }
    }
}
