import Foundation

enum AppRoute: Hashable {
    case search
    case allRecentCards
    case archiveDetail(CollectionKind)
    case cardDetail(InformationCard.ID)
    case cardCreationStart
    case settings
}
