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
    }

    func testCardEditDraftRequiresTitleAndSummary() {
        let missingTitle = CardEditDraft(
            collection: .schedule,
            title: "   ",
            summary: "예약 정보",
            body: "본문"
        )
        let missingSummary = CardEditDraft(
            collection: .schedule,
            title: "제주 숙소 예약 정보",
            summary: "\n",
            body: "본문"
        )

        XCTAssertFalse(missingTitle.isSavable)
        XCTAssertTrue(missingTitle.hasRequiredFieldError)
        XCTAssertFalse(missingSummary.isSavable)
        XCTAssertTrue(missingSummary.hasRequiredFieldError)
    }

    func testCardEditDraftRejectsTextBeyondFigmaLimits() {
        let draft = CardEditDraft(
            collection: .schedule,
            title: String(repeating: "가", count: CardEditDraft.titleLimit + 1),
            summary: "예약 정보",
            body: "본문"
        )

        XCTAssertFalse(draft.isSavable)
        XCTAssertFalse(draft.hasRequiredFieldError)
    }

    func testCardEditDraftNormalizesWhitespaceBeforeSaving() {
        let draft = CardEditDraft(
            collection: .schedule,
            title: "  제주 숙소 예약 정보  ",
            summary: "  예약 요약\n",
            body: "\n본문  "
        )

        XCTAssertEqual(
            draft.normalized(),
            CardEditDraft(
                collection: .schedule,
                title: "제주 숙소 예약 정보",
                summary: "예약 요약",
                body: "본문"
            )
        )
    }

    func testCardMutationPreservesOriginalImageThroughEditAndFavoriteChanges() {
        let card = SampleData.cards[1]
        let draft = CardEditDraft(
            collection: .knowledge,
            title: "수정된 제목",
            summary: "수정된 요약",
            body: "짧은 본문도 그대로 저장되어야 합니다."
        )

        let updatedCard = card
            .with(editDraft: draft)
            .with(isFavorite: true)

        XCTAssertEqual(updatedCard.memo, draft.body)
        XCTAssertEqual(updatedCard.originalImageAssetName, "InformationCardOriginal")
        XCTAssertEqual(updatedCard.detailImageAssetName, "InformationCardOriginal")
        XCTAssertTrue(updatedCard.isFavorite)
    }

    func testCardDetailImageStatesPreserveFigmaLayoutSpacing() {
        XCTAssertEqual(CardDetailImageState.loaded.imageTopInset, 0)
        XCTAssertEqual(CardDetailImageState.loaded.metadataSpacing, 22)
        XCTAssertEqual(CardDetailImageState.failedFullWidth.imageTopInset, 0)
        XCTAssertEqual(CardDetailImageState.failedFullWidth.metadataSpacing, 22)
        XCTAssertEqual(CardDetailImageState.failedCard.imageTopInset, 145)
        XCTAssertEqual(CardDetailImageState.failedCard.metadataSpacing, 20)
    }

}
