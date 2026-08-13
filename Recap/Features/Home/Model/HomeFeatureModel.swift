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
    /// 요약이 실릴 때마다 스냅샷을 정식 `Card`로 승격한다. 섹션이 스토어에서 읽는다.
    private let cardStore: CardStore?

    private(set) var state: State = .idle {
        didSet { upsertLoadedCards() }
    }

    init(
        summaryLoader: any HomeSummaryLoading,
        cardStore: CardStore? = nil
    ) {
        self.summaryLoader = summaryLoader
        self.cardStore = cardStore
    }

    private func upsertLoadedCards() {
        guard case .loaded(let content) = state else { return }
        cardStore?.upsert(content.recentCards)
        cardStore?.upsert(content.favoriteCards)
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
