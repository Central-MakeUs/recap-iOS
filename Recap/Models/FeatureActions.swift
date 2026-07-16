import Foundation

enum HomeAction: Hashable {
    case search
    case startOrganizing
    case openAllRecent
    case openCard(InformationCard.ID)
    case openArchive(CollectionKind)
    case openSettings
}

enum CardCreationAction: Hashable {
    case start
    case openSettings
}

enum ArchiveAction: Hashable {
    case search
    case openArchive(CollectionKind)
    case openCard(InformationCard.ID)
    case selectFilter(String)
    case deleteCards(Set<InformationCard.ID>)
    case openSettings
}

enum SearchAction: Hashable {
    case openCard(InformationCard.ID)
}
