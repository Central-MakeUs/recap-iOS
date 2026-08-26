import Foundation

nonisolated struct CardEditDraft: Equatable, Sendable {
    static let titleLimit = 30
    static let summaryLimit = 80
    static let bodyLimit = 1000

    var category: CardCategory
    var title: String
    var summary: String
    var body: String

    init(category: CardCategory, title: String, summary: String, body: String) {
        self.category = category
        self.title = title
        self.summary = summary
        self.body = body
    }

    @MainActor
    init(card: Card) {
        category = card.category
        title = card.title
        summary = card.summary
        body = card.memo
    }

    var trimmedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var trimmedSummary: String {
        summary.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var trimmedBody: String {
        body.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var isSavable: Bool {
        !trimmedTitle.isEmpty
            && !trimmedSummary.isEmpty
            && !trimmedBody.isEmpty
            && title.count <= Self.titleLimit
            && summary.count <= Self.summaryLimit
            && body.count <= Self.bodyLimit
    }

    var hasRequiredFieldError: Bool {
        trimmedTitle.isEmpty || trimmedSummary.isEmpty || trimmedBody.isEmpty
    }

    func normalized() -> CardEditDraft {
        var draft = self
        draft.title = trimmedTitle
        draft.summary = trimmedSummary
        draft.body = trimmedBody
        return draft
    }
}
