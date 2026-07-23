import Foundation

enum AppRoute: Hashable {
    case search
    case allRecentCards
    case archiveFavorites
    case archiveDetail(CollectionKind)
    case cardDetail(InformationCard.ID)
    case homeCardDetail(InformationCard)
    case cardCreationStart
    case settings
}
