import Observation

nonisolated enum CardDataChange: Sendable {
    case captureCreated
    case favoriteChanged
    case captureUpdated
    case captureDeleted
    case organizeResultAcknowledged
}

nonisolated struct ArchiveHomeRevision: Equatable, Hashable, Sendable {
    var types = 0
    var favorites = 0
    var other = 0

    func changedScopes(since previous: Self) -> ArchiveHomeRefreshScope {
        var scopes: ArchiveHomeRefreshScope = []
        if types != previous.types {
            scopes.insert(.types)
        }
        if favorites != previous.favorites {
            scopes.insert(.favorites)
        }
        if other != previous.other {
            scopes.insert(.other)
        }
        return scopes
    }
}

@MainActor
@Observable
final class CardDataInvalidationCenter {
    private(set) var homeRevision = 0
    private(set) var archiveHomeRevision = ArchiveHomeRevision()
    private(set) var archiveDetailRevision = 0
    private(set) var searchRevision = 0

    func invalidate(_ change: CardDataChange) {
        switch change {
        case .favoriteChanged:
            // 보관함 상세는 건드리지 않는다. 폴더 목록의 별 상태는 공유 `Card`로
            // 이미 실시간이고, 즐겨찾기 폴더에서 해제한 카드는 머무는 동안 남아
            // 있다가 다시 들어올 때 빠진다(사진 앱 즐겨찾기 앨범과 같은 규칙).
            // 즉시 빼면 잘못 누른 별을 되살릴 방법이 없다.
            homeRevision &+= 1
            archiveHomeRevision.favorites &+= 1
            searchRevision &+= 1
        case .captureCreated, .captureUpdated, .captureDeleted, .organizeResultAcknowledged:
            homeRevision &+= 1
            archiveHomeRevision.types &+= 1
            archiveHomeRevision.favorites &+= 1
            archiveHomeRevision.other &+= 1
            archiveDetailRevision &+= 1
            searchRevision &+= 1
        }
    }
}
