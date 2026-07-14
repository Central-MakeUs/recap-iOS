import SwiftUI

extension View {
    @MainActor
    func withAppNavigationDestinations() -> some View {
        navigationDestination(for: AppRoute.self) { route in
            destination(for: route)
        }
    }

    @MainActor
    func withAppPresentations(router: AppRouter, cardStore: RecapCardStore) -> some View {
        self
        .sheet(
            item: Binding(
                get: { router.presentedSheet },
                set: { router.presentedSheet = $0 }
            )
        ) { sheet in
            sheetDestination(for: sheet)
                .environment(router)
                .environment(cardStore)
        }
        .fullScreenCover(
            item: Binding(
                get: { router.presentedFullScreenCover },
                set: { router.presentedFullScreenCover = $0 }
            )
        ) { cover in
            fullScreenDestination(for: cover)
                .environment(router)
                .environment(cardStore)
        }
        .alert(
            router.presentedModal?.title ?? "",
            isPresented: Binding(
                get: { router.presentedModal != nil },
                set: { isPresented in
                    if !isPresented {
                        router.dismissModal()
                    }
                }
            ),
            presenting: router.presentedModal
        ) { modal in
            modalActions(for: modal, router: router, cardStore: cardStore)
        } message: { modal in
            Text(modal.message)
        }
    }

    @MainActor
    @ViewBuilder
    private func destination(for route: AppRoute) -> some View {
        switch route {
        case .search:
            SearchContainerView()
        case .allRecentCards:
            AllRecentCardsContainerView()
        case .archiveDetail(let kind):
            CollectionDetailContainerView(kind: kind)
        case .cardDetail(let id):
            CardDetailContainerView(cardID: id)
        case .cardEdit(let id):
            CardEditView(cardID: id)
        case .cardCreationStart:
            CardCreationFlowView()
        case .settings:
            SettingsContainerView()
        }
    }

    @MainActor
    @ViewBuilder
    private func sheetDestination(for sheet: AppSheetRoute) -> some View {
        switch sheet {
        case .sharePreview(let cardID):
            CardSharePreviewSheet(cardID: cardID)
        case .collectionPicker(let cardID):
            CollectionPickerSheet(cardID: cardID)
        }
    }

    @MainActor
    @ViewBuilder
    private func fullScreenDestination(for cover: AppFullScreenRoute) -> some View {
        switch cover {
        case .originalPreview(let cardID):
            CardOriginalPreviewSheet(cardID: cardID)
        }
    }

    @MainActor
    @ViewBuilder
    private func modalActions(
        for modal: AppModalRoute,
        router: AppRouter,
        cardStore: RecapCardStore
    ) -> some View {
        Button("취소", role: .cancel) {
            router.dismissModal()
        }

        switch modal {
        case .excludeCard(let cardID):
            Button("제외", role: .destructive) {
                cardStore.removeCard(id: cardID)
                router.dismissModal()
            }
        case .deleteCard(let cardID):
            Button("삭제", role: .destructive) {
                cardStore.removeCard(id: cardID)
                router.dismissModal()
            }
        }
    }
}
