import Foundation

enum AppRoute: Hashable {
    case search
    case allRecentCards
    case archiveDetail(CollectionKind)
    case cardDetail(InformationCard.ID)
    case cardEdit(InformationCard.ID)
    case organizeStart
    case settings
    case settingsDetail(SettingsRoute)
}

enum AppSheetRoute: Identifiable, Hashable {
    case originalPreview(cardID: InformationCard.ID)
    case sharePreview(cardID: InformationCard.ID)
    case collectionPicker(cardID: InformationCard.ID)

    var id: String {
        switch self {
        case .originalPreview(let cardID):
            "original-\(cardID.uuidString)"
        case .sharePreview(let cardID):
            "share-\(cardID.uuidString)"
        case .collectionPicker(let cardID):
            "collection-picker-\(cardID.uuidString)"
        }
    }
}

enum AppModalRoute: Identifiable, Hashable {
    case excludeCard(InformationCard.ID)
    case deleteCard(InformationCard.ID)

    var id: String {
        switch self {
        case .excludeCard(let cardID):
            "exclude-\(cardID.uuidString)"
        case .deleteCard(let cardID):
            "delete-\(cardID.uuidString)"
        }
    }

    var title: String {
        switch self {
        case .excludeCard:
            "RE-CAP에서 제외할까요?"
        case .deleteCard:
            "카드를 삭제할까요?"
        }
    }

    var message: String {
        switch self {
        case .excludeCard:
            "이 와이어프레임 단계에서는 제외 동작을 샘플 목록에서 숨기는 방식으로 확인합니다."
        case .deleteCard:
            "삭제하면 현재 샘플 목록과 상세 화면에서 더 이상 보이지 않아요."
        }
    }
}
