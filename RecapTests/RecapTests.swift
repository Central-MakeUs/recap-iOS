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

    func testRouterSwitchesBetweenMainTabs() {
        let router = AppRouter()

        router.switchTo(.archive)
        XCTAssertEqual(router.selectedTab, .archive)

        router.switchTo(.home)
        XCTAssertEqual(router.selectedTab, .home)
    }

    func testRouterOpensArchiveFavoritesSection() {
        let router = AppRouter()

        router.openArchive(section: .favorites)

        XCTAssertEqual(router.selectedTab, .archive)
        XCTAssertEqual(router.archiveSection, .favorites)
        XCTAssertEqual(router.archivePath, [.archiveFavorites])
    }

    func testMainTabChromeUsesFigmaGeometry() {
        XCTAssertEqual(RecapMainTabBarMetrics.height, 111)
        XCTAssertEqual(RecapMainTabBarMetrics.horizontalPadding, 22)
        XCTAssertEqual(RecapMainTabBarMetrics.topPadding, 28.5)
        XCTAssertEqual(RecapMainTabBarMetrics.selectorSize, CGSize(width: 155, height: 54))
        XCTAssertEqual(RecapMainTabBarMetrics.tabItemSize, CGSize(width: 72, height: 46))
        XCTAssertEqual(RecapMainTabBarMetrics.uploadButtonSize, CGSize(width: 107, height: 54))
        XCTAssertEqual(
            RecapMainTabBarMetrics.contentHeight(bottomSafeAreaInset: 30),
            81
        )

        let viewport = CGSize(width: 375, height: 812)
        XCTAssertEqual(
            RecapMainTabBarMetrics.barFrame(in: viewport),
            CGRect(x: 0, y: 701, width: 375, height: 111)
        )
        XCTAssertEqual(
            RecapMainTabBarMetrics.selectorFrame(in: viewport),
            CGRect(x: 22, y: 729.5, width: 155, height: 54)
        )
        XCTAssertEqual(
            RecapMainTabBarMetrics.uploadButtonFrame(in: viewport),
            CGRect(x: 246, y: 729.5, width: 107, height: 54)
        )
    }

    func testMainTabChromeRoutePolicy() {
        XCTAssertTrue(RecapMainTabChromePolicy.routeAllowsChrome(for: nil))
        XCTAssertFalse(RecapMainTabChromePolicy.routeAllowsChrome(for: .archiveFavorites))
        XCTAssertFalse(RecapMainTabChromePolicy.routeAllowsChrome(for: .archiveDetail(.shopping)))
        XCTAssertFalse(RecapMainTabChromePolicy.routeAllowsChrome(for: .search))
        XCTAssertFalse(RecapMainTabChromePolicy.routeAllowsChrome(for: .allRecentCards))
        XCTAssertFalse(RecapMainTabChromePolicy.routeAllowsChrome(for: .cardDetail(UUID())))
        XCTAssertFalse(
            RecapMainTabChromePolicy.routeAllowsChrome(
                for: .remoteCardDetail(SampleData.cards[0])
            )
        )
        XCTAssertFalse(RecapMainTabChromePolicy.routeAllowsChrome(for: .cardCreationStart))
        XCTAssertFalse(RecapMainTabChromePolicy.routeAllowsChrome(for: .settings))
    }

    func testCollectionSelectionChromeReplacesMainTabChrome() {
        let state = RecapMainTabChromeState()
        state.setVisible(false, for: .archive)

        XCTAssertFalse(
            RecapMainTabChromePolicy.showsChrome(
                routeAllowsChrome: true,
                contentVisibility: state.contentVisibility,
                selectedTab: .archive
            )
        )
        XCTAssertTrue(
            RecapMainTabChromePolicy.showsChrome(
                routeAllowsChrome: true,
                contentVisibility: state.contentVisibility,
                selectedTab: .home
            )
        )

        state.reset(for: .archive)
        XCTAssertTrue(
            RecapMainTabChromePolicy.showsChrome(
                routeAllowsChrome: true,
                contentVisibility: state.contentVisibility,
                selectedTab: .archive
            )
        )
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
