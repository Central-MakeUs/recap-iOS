import SwiftUI

extension View {
    @MainActor
    func withAppNavigationDestinations(
        cardStore: CardStore,
        homeSummaryLoader: any HomeSummaryLoading,
        archiveLoader: any ArchiveLoading,
        searchLoader: any SearchLoading,
        captureService: any CaptureServing,
        userAccountService: any UserAccountServing,
        cardCreationProcessor: any CardCreationProcessing,
        cardDataInvalidationCenter: CardDataInvalidationCenter,
        organizeNotificationStore: OrganizeNotificationStore,
        onCardDeleted: @escaping () -> Void,
        onAccountWithdrawalCompleted: @escaping () -> Void,
        onAccountDataDeleted: @escaping () -> Void
    ) -> some View {
        navigationDestination(for: AppRoute.self) { route in
            destination(
                for: route,
                cardStore: cardStore,
                homeSummaryLoader: homeSummaryLoader,
                archiveLoader: archiveLoader,
                searchLoader: searchLoader,
                captureService: captureService,
                userAccountService: userAccountService,
                cardCreationProcessor: cardCreationProcessor,
                cardDataInvalidationCenter: cardDataInvalidationCenter,
                organizeNotificationStore: organizeNotificationStore,
                onCardDeleted: onCardDeleted,
                onAccountWithdrawalCompleted: onAccountWithdrawalCompleted,
                onAccountDataDeleted: onAccountDataDeleted
            )
        }
    }

    @MainActor
    @ViewBuilder
    private func destination(
        for route: AppRoute,
        cardStore: CardStore,
        homeSummaryLoader: any HomeSummaryLoading,
        archiveLoader: any ArchiveLoading,
        searchLoader: any SearchLoading,
        captureService: any CaptureServing,
        userAccountService: any UserAccountServing,
        cardCreationProcessor: any CardCreationProcessing,
        cardDataInvalidationCenter: CardDataInvalidationCenter,
        organizeNotificationStore: OrganizeNotificationStore,
        onCardDeleted: @escaping () -> Void,
        onAccountWithdrawalCompleted: @escaping () -> Void,
        onAccountDataDeleted: @escaping () -> Void
    ) -> some View {
        switch route {
        case .search:
            SearchContainerView(
                loader: searchLoader,
                cardStore: cardStore,
                invalidationCenter: cardDataInvalidationCenter
            )
        case .allRecentCards:
            AllRecentCardsContainerView(
                summaryLoader: homeSummaryLoader,
                cardStore: cardStore,
                invalidationCenter: cardDataInvalidationCenter
            )
        case .archiveFavorites:
            ArchiveDetailContainerView(
                scope: .favorites,
                loader: archiveLoader,
                searchLoader: searchLoader,
                cardStore: cardStore,
                invalidationCenter: cardDataInvalidationCenter
            )
        case .archiveDetail(let category):
            ArchiveDetailContainerView(
                scope: .category(category),
                loader: archiveLoader,
                searchLoader: searchLoader,
                cardStore: cardStore,
                invalidationCenter: cardDataInvalidationCenter
            )
        case .remoteCardDetail(let captureID):
            RemoteCardDetailDestination(
                captureID: captureID,
                captureService: captureService,
                onDeleted: onCardDeleted
            )
        case .cardCreationStart:
            CardCreationFlowView(
                viewModel: CardCreationFlowViewModel(
                    processor: cardCreationProcessor,
                    invalidationCenter: cardDataInvalidationCenter,
                    notificationStore: organizeNotificationStore,
                    backgroundExecution: SystemOrganizeBackgroundExecution()
                )
            )
        case .cardEdit(let captureID):
            CardEditDestination(captureID: captureID)
        case .settings:
            SettingsContainerView(
                userAccountService: userAccountService,
                accountWithdrawalCompleted: onAccountWithdrawalCompleted,
                accountDataDeleted: onAccountDataDeleted
            )
        }
    }
}

/// 목록에서 스와이프로 곧장 여는 편집 화면.
///
/// 상세 화면 안에서 열 때와 달리 저장 동작을 넘기지 않는다. `CardEditView`가
/// 그때는 스토어로 직접 저장하므로, 목록에서 고친 내용도 같은 길로 반영된다.
private struct CardEditDestination: View {
    @Environment(CardStore.self) private var cardStore

    let captureID: Int64

    var body: some View {
        if let card = cardStore.card(withCaptureID: captureID) {
            CardEditView(card: card)
        } else {
            Color.recapBackground
        }
    }
}

private struct RemoteCardDetailDestination: View {
    @Environment(CardStore.self) private var cardStore

    /// 경로 페이로드는 captureID뿐이다. 상세로 보내는 화면은 전부 스토어의
    /// `Card`를 그리고 있으므로 조회가 실패할 일은 없다.
    let captureID: Int64
    let captureService: any CaptureServing
    let onDeleted: () -> Void

    var body: some View {
        if let card = cardStore.card(withCaptureID: captureID) {
            CardDetailView(
                card: card,
                captureService: captureService,
                cardStore: cardStore,
                onDeleted: onDeleted
            )
        } else {
            Color.recapBackground
        }
    }
}
