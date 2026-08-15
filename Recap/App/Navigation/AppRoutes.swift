import Foundation

enum AppRoute: Hashable {
    case search
    case allRecentCards
    case archiveFavorites
    case archiveDetail(CollectionKind)
    case remoteCardDetail(InformationCard)
    case cardCreationStart
    case settings
}
