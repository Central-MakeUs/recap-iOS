import Observation

nonisolated enum CardDataChange: Sendable {
    case captureCreated
    case favoriteChanged
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

    func invalidate(_ change: CardDataChange) {
        switch change {
        case .favoriteChanged:
            homeRevision &+= 1
            archiveHomeRevision.favorites &+= 1
            archiveDetailRevision &+= 1
        case .captureCreated, .captureDeleted, .organizeResultAcknowledged:
            homeRevision &+= 1
            archiveHomeRevision.types &+= 1
            archiveHomeRevision.favorites &+= 1
            archiveHomeRevision.other &+= 1
            archiveDetailRevision &+= 1
        }
    }
}
