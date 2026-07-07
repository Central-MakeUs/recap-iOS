import Foundation

enum HomeAction: Hashable {
    case search
    case openAllRecent
    case openCard(InformationCard.ID)
    case openArchive(CollectionKind)
    case openSettings
}

enum OrganizeAction: Hashable {
    case startSelection
    case openSettings
}

enum ArchiveAction: Hashable {
    case search
    case openArchive(CollectionKind)
    case openCard(InformationCard.ID)
    case selectFilter(String)
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
    case exclude(InformationCard.ID)
    case delete(InformationCard.ID)
}

enum SettingsAction: Hashable {
    case open(SettingsRoute)
}
