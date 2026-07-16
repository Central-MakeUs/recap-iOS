import SwiftUI

struct CardDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(RecapCardStore.self) private var cardStore

    let card: InformationCard
    let imageState: CardDetailImageState

    @State private var isDeleteConfirmationPresented: Bool
    @State private var toast: RecapToastContent?
    @State private var isActionPanelPresented = false
    @State private var isEditing = false
    @State private var isOriginalPresented = false
    @State private var pendingPanelAction: CardDetailPanelAction?

    private var navigationContentColor: Color {
        imageState == .failedCard ? RecapTheme.ColorToken.textPrimary : .white
    }

    private var displayedCard: InformationCard {
        cardStore.card(id: card.id) ?? card
    }

    init(
        card: InformationCard,
        imageState: CardDetailImageState = .loaded,
        initiallyShowsDeleteConfirmation: Bool = false,
        initialToast: RecapToastContent? = nil
    ) {
        self.card = card
        self.imageState = imageState
        _isDeleteConfirmationPresented = State(initialValue: initiallyShowsDeleteConfirmation)
        _toast = State(initialValue: initialToast)
        _pendingPanelAction = State(initialValue: nil)
    }

    var body: some View {
        ZStack(alignment: .top) {
            CardDetailContentView(
                card: displayedCard,
                imageState: imageState,
                onOpenOriginal: openOriginal
            )
                .ignoresSafeArea(edges: .top)

            CardDetailNavigationBar(
                title: "스크린샷 상세",
                isFavorite: displayedCard.isFavorite,
                foregroundColor: navigationContentColor,
                onBack: dismiss.callAsFunction,
                onFavorite: favorite,
                onMore: showActions
            )
            .padding(.top, 20)
        }
        .background(RecapTheme.ColorToken.background)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .sheet(
            isPresented: $isActionPanelPresented,
            onDismiss: handleActionPanelDismissal
        ) {
            CardDetailActionPanel(
                onEdit: requestEdit,
                onDelete: requestDelete,
                onClose: closeActionPanel
            )
            .presentationDetents([.height(236)])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(20)
        }
        .navigationDestination(isPresented: $isEditing) {
            CardEditView(card: displayedCard)
        }
        .fullScreenCover(isPresented: $isOriginalPresented) {
            CardOriginalPreviewSheet(card: displayedCard)
        }
        .recapConfirmationDialog(
            isPresented: $isDeleteConfirmationPresented,
            title: "스크린샷을 삭제할까요?",
            message: "삭제한 스크린샷 정보는\n되돌릴 수 없어요.",
            cancelTitle: "취소",
            confirmTitle: "삭제",
            onConfirm: deleteCard
        )
        .recapToast(toast)
        .task(id: toast) {
            await clearToastIfNeeded()
        }
    }

    private func openOriginal() { isOriginalPresented = true }
    private func showActions() { isActionPanelPresented = true }

    private func favorite() {
        let removesFavorite = displayedCard.isFavorite
        cardStore.toggleFavorite(id: card.id)
        toast = RecapToastContent(
            style: .success,
            message: removesFavorite
                ? "즐겨찾기에서 삭제했어요."
                : "즐겨찾기에 추가했어요."
        )
    }

    private func requestEdit() {
        pendingPanelAction = .edit
        isActionPanelPresented = false
    }

    private func requestDelete() {
        pendingPanelAction = .delete
        isActionPanelPresented = false
    }

    private func closeActionPanel() {
        pendingPanelAction = nil
        isActionPanelPresented = false
    }

    private func handleActionPanelDismissal() {
        defer { pendingPanelAction = nil }

        switch pendingPanelAction {
        case .edit:
            isEditing = true
        case .delete:
            isDeleteConfirmationPresented = true
        case nil:
            break
        }
    }

    private func deleteCard() {
        cardStore.removeCard(id: card.id)
        dismiss()
    }

    private func clearToastIfNeeded() async {
        guard toast != nil else { return }
        try? await Task.sleep(for: .seconds(2))
        guard !Task.isCancelled else { return }
        toast = nil
    }
}

private enum CardDetailPanelAction {
    case edit
    case delete
}

#Preview("정보카드 상세") {
    NavigationStack {
        CardDetailView(card: SampleData.cards[1])
    }
    .environment(AppRouter())
    .environment(PreviewStores.recapCardStore())
}
