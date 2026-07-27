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
    private let captureDeleter: any CaptureDeleting
    private let invalidationCenter: CardDataInvalidationCenter
    private(set) var state: State = .idle
    private(set) var sort: ArchiveSort = .latest

    init(
        scope: ArchiveDetailScope,
        loader: any ArchiveLoading,
        captureDeleter: any CaptureDeleting,
        invalidationCenter: CardDataInvalidationCenter
    ) {
        self.scope = scope
        self.loader = loader
        self.captureDeleter = captureDeleter
        self.invalidationCenter = invalidationCenter
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
        guard scope != .favorites, self.sort != sort else { return }
        self.sort = sort
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

        var deletedCardIDs: Set<InformationCard.ID> = []

        do {
            for (card, captureID) in zip(selectedCards, captureIDs) {
                try await captureDeleter.deleteCapture(captureID: captureID)
                deletedCardIDs.insert(card.id)
            }
        } catch {
            if !deletedCardIDs.isEmpty {
                state = .loaded(cards.filter { !deletedCardIDs.contains($0.id) })
                invalidationCenter.invalidate(.captureDeleted)
            }
            throw error
        }

        state = .loaded(cards.filter { !ids.contains($0.id) })
        invalidationCenter.invalidate(.captureDeleted)
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
