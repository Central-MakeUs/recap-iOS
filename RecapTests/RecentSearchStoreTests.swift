import Foundation
import XCTest
@testable import Recap

@MainActor
final class RecentSearchStoreTests: XCTestCase {
    func testRecordKeepsOnlyTenMostRecentKeywords() {
        let persistence = RecentSearchPersistenceSpy()
        let store = RecentSearchStore(persistence: persistence)

        for index in 1...11 {
            store.record("검색어 \(index)")
        }

        XCTAssertEqual(
            store.keywords,
            (2...11).reversed().map { "검색어 \($0)" }
        )
        XCTAssertEqual(persistence.savedKeywords, store.keywords)
    }

    func testRecordMovesDuplicateKeywordToFront() {
        let persistence = RecentSearchPersistenceSpy(
            loadedKeywords: ["첫 번째", "두 번째", "세 번째"]
        )
        let store = RecentSearchStore(persistence: persistence)

        store.record("  두   번째 ")

        XCTAssertEqual(store.keywords, ["두 번째", "첫 번째", "세 번째"])
    }

    func testRemoveAllClearsPersistedKeywords() {
        let persistence = RecentSearchPersistenceSpy(
            loadedKeywords: ["검색어"]
        )
        let store = RecentSearchStore(persistence: persistence)

        store.removeAll()

        XCTAssertTrue(store.keywords.isEmpty)
        XCTAssertEqual(persistence.savedKeywords, [])
    }

    func testRemoveDeletesOnlySelectedKeyword() {
        let persistence = RecentSearchPersistenceSpy(
            loadedKeywords: ["첫 번째", "두 번째", "세 번째"]
        )
        let store = RecentSearchStore(persistence: persistence)

        store.remove("두 번째")

        XCTAssertEqual(store.keywords, ["첫 번째", "세 번째"])
        XCTAssertEqual(persistence.savedKeywords, ["첫 번째", "세 번째"])
    }
}

private final class RecentSearchPersistenceSpy: RecentSearchPersisting {
    private let loadedKeywords: [String]
    private(set) var savedKeywords: [String]?

    init(loadedKeywords: [String] = []) {
        self.loadedKeywords = loadedKeywords
    }

    func loadKeywords() -> [String] {
        loadedKeywords
    }

    func saveKeywords(_ keywords: [String]) {
        savedKeywords = keywords
    }
}
