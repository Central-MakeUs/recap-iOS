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

    func reload() async {
        await load()
    }

    func reload(scopes: ArchiveHomeRefreshScope) async {
        guard case .loaded(let current) = state else {
            await load()
            return
        }
        guard !scopes.isEmpty else { return }

        do {
            state = .loaded(
                try await loader.refreshHome(current, scopes: scopes)
            )
        } catch is CancellationError {
            return
        } catch {
            state = .failed
        }
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
    private let captureMutator: any CaptureMutating
    private let invalidationCenter: CardDataInvalidationCenter
    /// 목록이 실릴 때마다 스냅샷을 정식 `Card`로 승격한다. 행이 스토어에서 읽는다.
    private let cardStore: CardStore?
    private(set) var state: State = .idle {
        didSet { upsertLoadedCards() }
    }
    private(set) var sort: ArchiveSort = .latest

    init(
        scope: ArchiveDetailScope,
        loader: any ArchiveLoading,
        captureMutator: any CaptureMutating,
        invalidationCenter: CardDataInvalidationCenter,
        cardStore: CardStore? = nil
    ) {
        self.scope = scope
        self.loader = loader
        self.captureMutator = captureMutator
        self.invalidationCenter = invalidationCenter
        self.cardStore = cardStore
    }

    private func upsertLoadedCards() {
        guard case .loaded(let cards) = state else { return }
        cardStore?.upsert(cards)
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

    func selectSort(_ sort: ArchiveSort) async {
        guard self.sort != sort else { return }
        self.sort = sort

        if scope == .favorites, case .loaded(let cards) = state {
            state = .loaded(sortedFavorites(cards))
            return
        }

        await load()
    }

    func deleteCards(ids: Set<InformationCard.ID>) async throws {
        guard case .loaded(let cards) = state else { return }

        let selectedCards = cards.filter { ids.contains($0.id) }
        let captureIDs = try selectedCards.map { card in
            guard let captureID = card.captureID else {
                throw CaptureLifecycleError.missingCaptureID
            }
            return captureID
        }

        try await captureMutator.deleteCaptures(captureIDs: captureIDs)

        state = .loaded(cards.filter { !ids.contains($0.id) })
        invalidationCenter.invalidate(.captureDeleted)
    }

    private func load() async {
        state = .loading

        do {
            let cards = try await loader.fetchCards(scope: scope, sort: sort)
            state = .loaded(
                scope == .favorites ? sortedFavorites(cards) : cards
            )
        } catch is CancellationError {
            state = .idle
        } catch {
            state = .failed
        }
    }

    private func sortedFavorites(_ cards: [InformationCard]) -> [InformationCard] {
        cards.enumerated()
            .sorted { lhs, rhs in
                switch (lhs.element.organizedAt, rhs.element.organizedAt) {
                case let (left?, right?) where left != right:
                    return sort == .latest ? left > right : left < right
                case (_?, nil):
                    return true
                case (nil, _?):
                    return false
                default:
                    return lhs.offset < rhs.offset
                }
            }
            .map(\.element)
    }
}
