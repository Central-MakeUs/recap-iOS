import XCTest
@testable import Recap

@MainActor
final class RecapTests: XCTestCase {
    func testApplicationModuleLoads() {
        XCTAssertTrue(true)
    }

    func testCardCreationFlowRequiresASelectionBeforeConfirmation() {
        XCTAssertEqual(
            CardCreationFlowDecision.confirmationStep(selectedCount: 0),
            .noSelection
        )
    }

    func testCardCreationFlowMovesFromConfirmationToProcessing() {
        XCTAssertEqual(
            CardCreationFlowDecision.confirmationStep(selectedCount: 1),
            .confirming
        )
    }

    func testCardCreationFlowReportsPartialFailureWhenSomeLoadsFail() {
        XCTAssertEqual(
            CardCreationFlowDecision.processingResult(
                failedCount: 1,
                hasScreenshots: true
            ),
            .partialFailure
        )
    }

    func testRouterKeepsNavigationPathsIndependentByTab() {
        let homePath = AppNavigationPath.appending(.search, to: [])
        let cardCreationPath = AppNavigationPath.appending(.cardCreationStart, to: [])

        XCTAssertEqual(homePath, [.search])
        XCTAssertEqual(cardCreationPath, [.cardCreationStart])
    }

    func testCardStoreSearchesAndUpdatesCards() {
        let card = SampleData.cards[0]
        XCTAssertEqual(
            RecapCardCollection.search([card], query: card.title).map(\.id),
            [card.id]
        )

        let favoriteCards = RecapCardCollection.togglingFavorite(
            cardID: card.id,
            in: [card]
        )
        XCTAssertTrue(favoriteCards[0].isFavorite)

        let movedCards = RecapCardCollection.moving(
            cardID: card.id,
            in: favoriteCards,
            to: .knowledge
        )
        XCTAssertEqual(movedCards[0].collection, .knowledge)
    }
}
