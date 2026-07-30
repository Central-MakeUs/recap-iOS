import Foundation
import Observation

protocol RecentSearchPersisting {
    func loadKeywords() -> [String]
    func saveKeywords(_ keywords: [String])
}

struct UserDefaultsRecentSearchPersistence: RecentSearchPersisting {
    private let userDefaults: UserDefaults
    private let key: String

    init(
        userDefaults: UserDefaults = .standard,
        key: String = "search.recentKeywords"
    ) {
        self.userDefaults = userDefaults
        self.key = key
    }

    func loadKeywords() -> [String] {
        userDefaults.stringArray(forKey: key) ?? []
    }

    func saveKeywords(_ keywords: [String]) {
        userDefaults.set(keywords, forKey: key)
    }
}

struct InMemoryRecentSearchPersistence: RecentSearchPersisting {
    var keywords: [String]

    func loadKeywords() -> [String] {
        keywords
    }

    func saveKeywords(_ keywords: [String]) {}
}

@MainActor
@Observable
final class RecentSearchStore {
    private static let maximumCount = 10

    private let persistence: any RecentSearchPersisting
    private(set) var keywords: [String]

    convenience init() {
        self.init(persistence: UserDefaultsRecentSearchPersistence())
    }

    init(persistence: any RecentSearchPersisting) {
        self.persistence = persistence
        keywords = Array(
            persistence.loadKeywords()
                .filter { !$0.isEmpty }
                .prefix(Self.maximumCount)
        )
    }

    func record(_ rawKeyword: String) {
        let keyword = normalized(rawKeyword)
        guard !keyword.isEmpty else { return }

        keywords.removeAll { $0 == keyword }
        keywords.insert(keyword, at: 0)
        keywords = Array(keywords.prefix(Self.maximumCount))
        persistence.saveKeywords(keywords)
    }

    func removeAll() {
        keywords.removeAll()
        persistence.saveKeywords([])
    }

    func remove(_ keyword: String) {
        keywords.removeAll { $0 == keyword }
        persistence.saveKeywords(keywords)
    }

    private func normalized(_ keyword: String) -> String {
        keyword
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
    }
}
