import Foundation

enum HomeAction: Hashable {
    case search
    case startOrganizing
    case openAllRecent
    case openCard(InformationCard.ID)
    case openArchive(CollectionKind)
    case openSettings
}

enum OrganizeAction: Hashable {
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

enum CardDetailAction: Hashable {
    case openOriginal(InformationCard.ID)
    case share(InformationCard.ID)
    case edit(InformationCard.ID)
    case changeCollection(InformationCard.ID)
    case toggleFavorite(InformationCard.ID)
    case exclude(InformationCard.ID)
    case delete(InformationCard.ID)
}

enum SettingsAction: Hashable {
    case open(SettingsRoute)
}
