import Foundation

struct CardEditDraft: Equatable {
    var collection: CollectionKind
    var title: String
    var summary: String
    var body: String

    init(collection: CollectionKind, title: String, summary: String, body: String) {
        self.collection = collection
        self.title = title
        self.summary = summary
        self.body = body
    }

    init(card: InformationCard) {
        collection = card.collection
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
        !trimmedTitle.isEmpty && !trimmedSummary.isEmpty
    }

    func normalized() -> CardEditDraft {
        var draft = self
        draft.title = trimmedTitle
        draft.summary = trimmedSummary
        draft.body = trimmedBody
        return draft
    }
}
