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
    private let captureMutator: (any CaptureMutating)?
    private let invalidationCenter: CardDataInvalidationCenter?

    private(set) var state: State = .idle

    /// 즐겨찾기를 변경하지 않는 화면은 `captureMutator` 없이 요약만 사용한다.
    init(
        summaryLoader: any HomeSummaryLoading,
        captureMutator: (any CaptureMutating)? = nil,
        invalidationCenter: CardDataInvalidationCenter? = nil
    ) {
        self.summaryLoader = summaryLoader
        self.captureMutator = captureMutator
        self.invalidationCenter = invalidationCenter
    }

    func toggleFavorite(cardID: InformationCard.ID) async throws -> Bool {
        guard
            case .loaded(let content) = state,
            let captureMutator,
            let card = content.recentCards.first(where: { $0.id == cardID }),
            let captureID = card.captureID
        else {
            throw CaptureLifecycleError.missingCaptureID
        }

        let targetValue = !card.isFavorite
        state = .loaded(content.applyingFavorite(targetValue, captureID: captureID))

        do {
            try await captureMutator.updateFavorite(
                captureID: captureID,
                isFavorite: targetValue
            )
            invalidationCenter?.invalidate(.favoriteChanged)
            return targetValue
        } catch {
            state = .loaded(content)
            throw error
        }
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
