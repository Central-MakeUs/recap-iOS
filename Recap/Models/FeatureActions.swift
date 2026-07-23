import Foundation

enum HomeAction: Hashable {
    case search
    case startOrganizing
    case openFavorites
    case openAllRecent
    case openCard(InformationCard)
    case openArchive(CollectionKind)
    case openSettings
}

enum CardCreationAction: Hashable {
    case start
    case openSettings
}

enum ArchiveSection: String, CaseIterable, Identifiable {
    case favorites = "즐겨찾기"
    case type = "유형별 보기"
    case other = "기타"

    var id: String { rawValue }
}

enum ArchiveAction: Hashable {
    case search
    case openFavorites
    case openArchive(CollectionKind)
    case openCard(InformationCard)
    case selectFilter(String)
    case deleteCards(Set<InformationCard.ID>)
    case openSettings
}

enum SearchAction: Hashable {
    case openCard(InformationCard.ID)
}
