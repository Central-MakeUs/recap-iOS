#if DEBUG
import Foundation

actor PreviewCardRepository {
    private var cards: [InformationCard]

    init(cards: [InformationCard] = SampleData.cards) {
        self.cards = cards
    }

    func allCards() -> [InformationCard] {
        cards
    }

    func card(captureID: Int64) throws -> InformationCard {
        guard let card = cards.first(where: { $0.captureID == captureID }) else {
            throw CaptureLifecycleError.missingCaptureID
        }
        return card
    }

    func updateFavorite(captureID: Int64, isFavorite: Bool) throws {
        guard let index = cards.firstIndex(where: { $0.captureID == captureID }) else {
            throw CaptureLifecycleError.missingCaptureID
        }
        cards[index].isFavorite = isFavorite
    }

    func updateCard(captureID: Int64, draft: CardEditDraft) throws {
        guard let index = cards.firstIndex(where: { $0.captureID == captureID }) else {
            throw CaptureLifecycleError.missingCaptureID
        }
        cards[index] = cards[index].with(editDraft: draft.normalized())
    }

    func deleteCard(captureID: Int64) throws {
        guard cards.contains(where: { $0.captureID == captureID }) else {
            throw CaptureLifecycleError.missingCaptureID
        }
        cards.removeAll { $0.captureID == captureID }
    }

    func deleteCards(captureIDs: [Int64]) {
        let ids = Set(captureIDs)
        cards.removeAll { ids.contains($0.captureID) }
    }
}
#endif
