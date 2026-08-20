import Foundation

private struct DemoCardsFixture: Decodable {
    let cards: [DemoCardFixture]
}

private struct DemoCardFixture: Decodable {
    let sourceFileName: String
    let captureID: Int64
    let category: String
    let title: String
    let summary: String
    let body: String
    let organizedAt: Date?
    let isFavorite: Bool

    func snapshot() -> CardSnapshot {
        let assetName = "DemoScreenshot\(sourceFileName.prefix(2))"

        return CardSnapshot(
            captureID: captureID,
            title: title,
            summary: summary,
            category: CardCategory(rawValue: category) ?? .other,
            organizedAt: organizedAt,
            location: "",
            businessHours: "",
            confirmationLabel: nil,
            memo: body,
            tags: [],
            originalImageAssetName: assetName,
            thumbnailAssetName: assetName,
            isFavorite: isFavorite
        )
    }
}

actor DemoFixtureRepository {
    private var cards: [Int64: CardSnapshot]
    private let originalOrder: [Int64]

    init(cards: [CardSnapshot]) {
        self.cards = Dictionary(uniqueKeysWithValues: cards.map { ($0.captureID, $0) })
        originalOrder = cards.map(\.captureID)
    }

    static func loadFromBundle(bundle: Bundle = .main) -> DemoFixtureRepository {
        guard let url = bundle.url(forResource: "DemoCards", withExtension: "json"),
              let data = try? Data(contentsOf: url)
        else {
            preconditionFailure("DemoCards.json이 번들에 없습니다.")
        }

        let decoder = JSONDecoder.recapAPI
        guard let fixture = try? decoder.decode(DemoCardsFixture.self, from: data), fixture.cards.count == 20 else {
            preconditionFailure("DemoCards.json은 분석 완료된 20개 카드여야 합니다.")
        }

        return DemoFixtureRepository(cards: fixture.cards.map { $0.snapshot() })
    }

    func allCards() -> [CardSnapshot] {
        originalOrder.compactMap { cards[$0] }
    }

    func card(captureID: Int64) throws -> CardSnapshot {
        guard let card = cards[captureID] else {
            throw CaptureLifecycleError.missingCaptureID
        }
        return card
    }

    func updateFavorite(captureID: Int64, isFavorite: Bool) throws {
        guard var card = cards[captureID] else {
            throw CaptureLifecycleError.missingCaptureID
        }
        card.isFavorite = isFavorite
        cards[captureID] = card
    }

    func updateCard(captureID: Int64, draft: CardEditDraft) throws {
        guard let card = cards[captureID] else {
            throw CaptureLifecycleError.missingCaptureID
        }
        cards[captureID] = card.with(editDraft: draft.normalized())
    }

    func delete(captureIDs: [Int64]) {
        captureIDs.forEach { cards[$0] = nil }
    }
}

@MainActor
final class DemoHomeSummaryLoader: HomeSummaryLoading {
    private let repository: DemoFixtureRepository

    init(repository: DemoFixtureRepository) {
        self.repository = repository
    }

    func fetchSummary() async throws -> HomeSummaryContent {
        let cards = await repository.allCards()
        return HomeSummaryContent(
            recentCards: Array(cards.prefix(3)),
            favoriteCards: cards.filter(\.isFavorite),
            frequentTypes: categorySummaries(from: cards),
            hasAnyCapture: !cards.isEmpty
        )
    }

    func fetchRecentCaptures(page: Int, size: Int) async throws -> RecentCapturesPage {
        let cards = await repository.allCards()
        let offset = max(0, page * size)
        let pageCards = Array(cards.dropFirst(offset).prefix(size))

        return RecentCapturesPage(
            totalCount: cards.count,
            hasNext: offset + pageCards.count < cards.count,
            cards: pageCards
        )
    }
}

@MainActor
final class DemoArchiveLoader: ArchiveLoading {
    private let repository: DemoFixtureRepository

    init(repository: DemoFixtureRepository) {
        self.repository = repository
    }

    func fetchHome() async throws -> ArchiveHomeContent {
        let cards = await repository.allCards()
        let categories = categorySummaries(from: cards)
        let otherCount = cards.filter { $0.category == .other }.count

        return ArchiveHomeContent(
            summaries: categories,
            favoriteCount: cards.filter(\.isFavorite).count,
            otherCount: otherCount
        )
    }

    func fetchCards(scope: ArchiveDetailScope, sort: ArchiveSort) async throws -> [CardSnapshot] {
        let allCards = await repository.allCards()
        let scopedCards: [CardSnapshot]

        switch scope {
        case .favorites:
            scopedCards = allCards.filter(\.isFavorite)
        case .category(let category):
            scopedCards = allCards.filter { $0.category == category }
        }

        return sortCards(scopedCards, sort: sort)
    }
}

@MainActor
final class DemoSearchLoader: SearchLoading {
    private let repository: DemoFixtureRepository

    init(repository: DemoFixtureRepository) {
        self.repository = repository
    }

    func search(
        query: String,
        scope: SearchScope,
        page: Int,
        size: Int
    ) async throws -> SearchPage {
        let cards = await repository.allCards()
        let results = cards
            .filter { card in matches(card: card, scope: scope) }
            .filter { card in
                query.isEmpty || card.title.localizedCaseInsensitiveContains(query)
                    || card.summary.localizedCaseInsensitiveContains(query)
                    || card.memo.localizedCaseInsensitiveContains(query)
            }
            .map(SearchResult.init(card:))
        let offset = max(0, page * size)
        let items = Array(results.dropFirst(offset).prefix(size))

        return SearchPage(
            count: results.count,
            hasNext: offset + items.count < results.count,
            items: items
        )
    }
}

actor DemoCaptureService: CaptureServing {
    private let repository: DemoFixtureRepository

    init(repository: DemoFixtureRepository) {
        self.repository = repository
    }

    func issueUploadURLs(count: Int) async throws -> [UploadItemDTO] { throw APIError.offline }
    func organize(imageKeys: [String]) async throws -> OrganizeResponseDTO { throw APIError.offline }
    func organizeStatus(batchID: Int64) async throws -> OrganizeStatusResponseDTO { throw APIError.offline }
    func cancelOrganize(batchID: Int64) async throws { throw APIError.offline }
    func pendingOrganizeResult() async throws -> PendingOrganizeResultDTO? { nil }
    func acknowledgeOrganizeResult(batchID: Int64) async throws {}

    func captureDetail(captureID: Int64) async throws -> CardSnapshot {
        try await repository.card(captureID: captureID)
    }

    func updateFavorite(captureID: Int64, isFavorite: Bool) async throws {
        try await repository.updateFavorite(captureID: captureID, isFavorite: isFavorite)
    }

    func updateCapture(captureID: Int64, draft: CardEditDraft) async throws {
        try await repository.updateCard(captureID: captureID, draft: draft)
    }

    func deleteCapture(captureID: Int64) async throws {
        await repository.delete(captureIDs: [captureID])
    }

    func deleteCaptures(captureIDs: [Int64]) async throws {
        await repository.delete(captureIDs: captureIDs)
    }

    func reportCapture(
        captureID: Int64,
        reason: CaptureReportReason,
        detail: String?
    ) async throws {}
}

@MainActor
final class DemoUserAccountService: UserAccountServing {
    private let repository: DemoFixtureRepository

    init(repository: DemoFixtureRepository) {
        self.repository = repository
    }

    func fetchAccountInfo() async throws -> UserAccountInfo {
        UserAccountInfo(provider: nil, createdAt: .now)
    }

    func fetchDataSummary() async throws -> UserDataSummary {
        UserDataSummary(capturedCount: await repository.allCards().count)
    }

    func withdrawAccount() async throws { throw APIError.offline }

    func deleteAllData() async throws {
        let ids = await repository.allCards().map(\.captureID)
        await repository.delete(captureIDs: ids)
    }
}

actor DemoCardCreationProcessor: CardCreationProcessing {
    func process(
        images: [Data],
        progress: @escaping @MainActor @Sendable (CardCreationProgress) -> Void
    ) async throws -> OrganizeStatusResponseDTO {
        throw APIError.offline
    }

    func cancelCurrentProcess() async {}
}

@MainActor
final class DemoAIDataTransferConsentService: AIDataTransferConsentServing {
    private var status = AIDataTransferConsentStatus(hasConsented: true, consentedAt: .now)

    func fetchConsentStatus() async throws -> AIDataTransferConsentStatus { status }
    func grantConsent() async throws { status = AIDataTransferConsentStatus(hasConsented: true, consentedAt: .now) }
    func revokeConsent() async throws { status = AIDataTransferConsentStatus(hasConsented: false, consentedAt: nil) }
}

private func categorySummaries(from cards: [CardSnapshot]) -> [CategorySummary] {
    CardCategory.folderCases.compactMap { category in
        let categoryCards = cards.filter { $0.category == category }
        guard !categoryCards.isEmpty else { return nil }
        return CategorySummary(
            category: category,
            count: categoryCards.count,
            previewTitle: categoryCards.prefix(2).map(\.title).joined(separator: " · ")
        )
    }
}

private func sortCards(_ cards: [CardSnapshot], sort: ArchiveSort) -> [CardSnapshot] {
    cards.sorted { left, right in
        let leftDate = left.organizedAt ?? .distantPast
        let rightDate = right.organizedAt ?? .distantPast
        return sort == .latest ? leftDate > rightDate : leftDate < rightDate
    }
}

private func matches(card: CardSnapshot, scope: SearchScope) -> Bool {
    switch scope {
    case .all:
        true
    case .favorites:
        card.isFavorite
    case .other:
        card.category == .other
    case .type(let category):
        card.category == category
    }
}
