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
            // 별 상태는 공유 `Card`로 모든 화면에서 실시간이라, 재조회가 필요한
            // 곳은 서버 사실(즐겨찾기 개수)을 보여주는 보관함 홈뿐이다.
            // - 홈: 루트로 돌아올 때마다 어차피 전체 재조회한다
            // - 검색: 결과 소속이 즐겨찾기와 무관하다
            // - 보관함 상세: 폴더에 머무는 동안 카드를 유지한다(사진 앱 즐겨찾기
            //   앨범과 같은 규칙). 즉시 빼면 잘못 누른 별을 되살릴 방법이 없다
            archiveHomeRevision.favorites &+= 1
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
