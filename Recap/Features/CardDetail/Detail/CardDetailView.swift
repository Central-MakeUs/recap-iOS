import SwiftUI

struct CardDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(RecapCardStore.self) private var cardStore

    let imageState: CardDetailImageState
    let onDeleted: () -> Void

    @State private var model: CaptureDetailFeatureModel
    @State private var isDeleteConfirmationPresented: Bool
    @State private var toast: RecapToastContent?
    @State private var isActionPanelPresented = false
    @State private var isEditing = false
    @State private var isOriginalPresented = false
    @State private var isReportReasonPresented = false
    @State private var selectedReportReason: CaptureReportReason?
    @State private var pendingPanelAction: CardDetailPanelAction?
    @State private var isFavoriteMutationRunning = false

    private var navigationContentColor: Color {
        imageState == .failedCard ? Color.recapGray900 : .white
    }

    private var displayedCard: InformationCard {
        model.card
    }

    private var reportSheetHeight: CGFloat {
        selectedReportReason == .other ? 453 : 375
    }

    @MainActor
    init(
        card: InformationCard,
        captureService: any CaptureServing,
        invalidationCenter: CardDataInvalidationCenter,
        imageState: CardDetailImageState = .loaded,
        initiallyShowsDeleteConfirmation: Bool = false,
        initialToast: RecapToastContent? = nil,
        onDeleted: @escaping () -> Void = {}
    ) {
        self.imageState = imageState
        self.onDeleted = onDeleted
        _model = State(
            initialValue: CaptureDetailFeatureModel(
                card: card,
                captureService: captureService,
                invalidationCenter: invalidationCenter
            )
        )
        _isDeleteConfirmationPresented = State(initialValue: initiallyShowsDeleteConfirmation)
        _toast = State(initialValue: initialToast)
        _selectedReportReason = State(initialValue: nil)
        _pendingPanelAction = State(initialValue: nil)
    }

#if DEBUG
    /// 프리뷰 전용. 실제 화면은 captureService를 주입받는 init을 쓴다.
    @MainActor
    init(
        card: InformationCard,
        imageState: CardDetailImageState = .loaded,
        initiallyShowsDeleteConfirmation: Bool = false,
        initialToast: RecapToastContent? = nil,
        onDeleted: @escaping () -> Void = {}
    ) {
        self.init(
            card: card,
            captureService: PreviewCaptureService(),
            invalidationCenter: CardDataInvalidationCenter(),
            imageState: imageState,
            initiallyShowsDeleteConfirmation: initiallyShowsDeleteConfirmation,
            initialToast: initialToast,
            onDeleted: onDeleted
        )
    }

#endif
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .top) {
                CardDetailContentView(
                    card: displayedCard,
                    imageState: imageState,
                    contentWidth: geometry.size.width,
                    onOpenOriginal: openOriginal,
                    onRemoteImageFailure: refreshRemoteImageURL
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
                .frame(width: geometry.size.width)
                .padding(.top, 20)
            }
            .frame(
                width: geometry.size.width,
                height: geometry.size.height,
                alignment: .top
            )
        }
        .background(Color.recapBackground)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .interactivePopGestureEnabled()
        .recapBottomSheet(
            isPresented: $isActionPanelPresented,
            height: 288,
            cornerRadius: 20,
            onDismiss: handleActionPanelDismissal
        ) {
            CardDetailActionPanel(
                onEdit: requestEdit,
                onDelete: requestDelete,
                onReport: requestReport,
                onClose: closeActionPanel
            )
        }
        .recapBottomSheet(
            isPresented: $isReportReasonPresented,
            height: reportSheetHeight,
            cornerRadius: 20,
            onDismiss: resetReportSheet
        ) {
            CardDetailReportSheet(
                selectedReason: $selectedReportReason,
                onSubmit: report,
                onClose: closeReportSheet
            )
        }
        .navigationDestination(isPresented: $isEditing) {
            CardEditView(
                card: displayedCard,
                onSave: saveCardEdit
            )
        }
        .fullScreenCover(isPresented: $isOriginalPresented) {
            CardOriginalPreviewSheet(
                card: displayedCard,
                onRemoteImageFailure: refreshRemoteImageURL
            )
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
        .task {
            await model.loadDetail()
            cardStore.cacheRemoteCards([model.card])
        }
    }

    private func openOriginal() { isOriginalPresented = true }
    private func showActions() { isActionPanelPresented = true }

    private func refreshRemoteImageURL(_ failedURL: URL) {
        Task {
            await model.refreshImageURLAfterFailure(failedURL)
            cardStore.cacheRemoteCards([model.card])
        }
    }

    private func favorite() {
        guard !isFavoriteMutationRunning else { return }
        isFavoriteMutationRunning = true

        Task {
            defer { isFavoriteMutationRunning = false }

            do {
                let isFavorite = try await model.toggleFavorite()
                cardStore.cacheRemoteCards([model.card])
                toast = RecapToastMessage.favoriteToggled(isFavorite: isFavorite).content
            } catch {
                toast = RecapToastMessage.favoriteChangeFailed.content
            }
        }
    }

    private func saveCardEdit(_ draft: CardEditDraft) async throws {
        try await model.update(with: draft)
        cardStore.cacheRemoteCards([model.card])
    }

    private func requestEdit() {
        pendingPanelAction = .edit
        isActionPanelPresented = false
    }

    private func requestDelete() {
        pendingPanelAction = .delete
        isActionPanelPresented = false
    }

    private func requestReport() {
        pendingPanelAction = .report
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
        case .report:
            isReportReasonPresented = true
        case nil:
            break
        }
    }

    private func report(_ reason: CaptureReportReason, detail: String?) {
        isReportReasonPresented = false
        Task {
            do {
                try await model.report(reason: reason, detail: detail)
                toast = RecapToastMessage.reportAccepted.content
            } catch {
                toast = RecapToastMessage.reportFailed.content
            }
        }
    }

    private func closeReportSheet() {
        isReportReasonPresented = false
    }

    private func resetReportSheet() {
        selectedReportReason = nil
    }

    private func deleteCard() {
        Task {
            do {
                try await model.delete()
                cardStore.removeCard(id: displayedCard.id)
                onDeleted()
                dismiss()
            } catch {
                toast = RecapToastMessage.screenshotDeleteFailed.content
            }
        }
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
    case report
}

#if DEBUG
#Preview("정보카드 상세") {
    NavigationStack {
        CardDetailView(card: SampleData.cards[1])
    }
    .environment(AppRouter())
    .environment(PreviewStores.recapCardStore())
}
#endif
