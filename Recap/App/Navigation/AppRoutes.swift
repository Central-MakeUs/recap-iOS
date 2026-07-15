import Foundation

enum AppRoute: Hashable {
    case search
    case allRecentCards
    case archiveDetail(CollectionKind)
    case cardDetail(InformationCard.ID)
    case cardEdit(InformationCard.ID)
    case cardCreationStart
    case settings
}

enum AppFullScreenRoute: Identifiable, Hashable {
    case originalPreview(cardID: InformationCard.ID)

    var id: String {
        switch self {
        case .originalPreview(let cardID):
            "original-\(cardID.uuidString)"
        }
    }
}

enum AppModalRoute: Identifiable, Hashable {
    case deleteCard(InformationCard.ID)

    var id: String {
        switch self {
        case .deleteCard(let cardID):
            "delete-\(cardID.uuidString)"
        }
    }

    var title: String {
        switch self {
        case .deleteCard:
            "카드를 삭제할까요?"
        }
    }

    var message: String {
        switch self {
        case .deleteCard:
            "삭제하면 현재 샘플 목록과 상세 화면에서 더 이상 보이지 않아요."
        }
    }
}
