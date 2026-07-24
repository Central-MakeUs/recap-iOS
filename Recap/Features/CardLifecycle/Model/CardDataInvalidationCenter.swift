import Observation

@MainActor
@Observable
final class CardDataInvalidationCenter {
    private(set) var revision = 0

    func invalidate() {
        revision &+= 1
    }
}
