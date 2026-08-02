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
    @State private var pendingPanelAction: CardDetailPanelAction?
    @State private var isFavoriteMutationRunning = false

    private var navigationContentColor: Color {
        imageState == .failedCard ? Color.recapGray900 : .white
    }

    private var displayedCard: InformationCard {
        model.card
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
        _pendingPanelAction = State(initialValue: nil)
    }

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
        .sheet(
            isPresented: $isActionPanelPresented,
            onDismiss: handleActionPanelDismissal
        ) {
            CardDetailActionPanel(
                onEdit: requestEdit,
                onDelete: requestDelete,
                onReport: requestReport,
                onClose: closeActionPanel
            )
            .presentationDetents([.height(288)])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(20)
        }
        .sheet(isPresented: $isReportReasonPresented) {
            CardDetailReportSheet(onSubmit: report)
                .presentationDetents([.height(453)])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(20)
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
                toast = RecapToastContent(
                    style: .success,
                    message: isFavorite
                        ? "즐겨찾기에 추가했어요."
                        : "즐겨찾기에서 삭제했어요."
                )
            } catch {
                toast = RecapToastContent(
                    style: .error,
                    message: "즐겨찾기를 변경하지 못했어요. 다시 시도해주세요."
                )
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
                toast = RecapToastContent(
                    style: .success,
                    message: "신고가 접수됐어요. 검토 후 개선에 반영할게요."
                )
            } catch {
                toast = RecapToastContent(
                    style: .error,
                    message: "신고를 접수하지 못했어요. 다시 시도해주세요."
                )
            }
        }
    }

    private func deleteCard() {
        Task {
            do {
                try await model.delete()
                cardStore.removeCard(id: displayedCard.id)
                onDeleted()
                dismiss()
            } catch {
                toast = RecapToastContent(
                    style: .error,
                    message: "스크린샷을 삭제하지 못했어요. 다시 시도해주세요."
                )
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

#Preview("정보카드 상세") {
    NavigationStack {
        CardDetailView(card: SampleData.cards[1])
    }
    .environment(AppRouter())
    .environment(PreviewStores.recapCardStore())
}
