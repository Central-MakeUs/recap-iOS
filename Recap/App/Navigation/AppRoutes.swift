import Foundation

enum AppRoute: Hashable {
    case search
    case allRecentCards
    case archiveFavorites
    case archiveDetail(CardCategory)
    /// 페이로드는 captureID뿐이다. 카드 자체는 `CardStore`의 공유 인스턴스를 쓴다.
    case remoteCardDetail(Int64)
    case cardCreationStart
    case settings
}
