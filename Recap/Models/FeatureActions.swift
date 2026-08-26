import Foundation

enum HomeAction: Hashable {
    case search
    case startOrganizing
    case openFavorites
    case openAllRecent
    case openCard(Int64)
    case openArchive(CardCategory)
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
    case openArchive(CardCategory)
    case openCard(Int64)
    case editCard(Int64)
    case selectSort(ArchiveSort)
    case openSettings
}

enum SearchAction: Hashable {
    case openCard(Int64)
    case editCard(Int64)
}
