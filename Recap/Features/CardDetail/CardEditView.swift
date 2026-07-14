import SwiftUI

struct CardEditView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppRouter.self) private var router
    @Environment(RecapCardStore.self) private var cardStore

    let cardID: InformationCard.ID

    var body: some View {
        if let card = cardStore.card(id: cardID) {
            CardEditScreen(
                card: card,
                onSave: save,
                onOpenOriginal: { router.presentFullScreenCover(.originalPreview(cardID: cardID)) },
                onClose: dismiss.callAsFunction
            )
        } else {
            MissingCardView(cardID: cardID)
        }
    }

    private func save(_ draft: CardEditDraft) -> Bool {
        cardStore.updateCard(id: cardID, with: draft.normalized())
        dismiss()
        return true
    }
}

struct CardEditScreen: View {
    let card: InformationCard
    let onSave: (CardEditDraft) -> Bool
    let onOpenOriginal: () -> Void
    let onClose: () -> Void

    @State private var draft: CardEditDraft
    @State private var overlayState: CardEditOverlayState

    private let originalDraft: CardEditDraft

    init(
        card: InformationCard,
        initialDraft: CardEditDraft? = nil,
        initialOverlay: CardEditOverlayState = .none,
        onSave: @escaping (CardEditDraft) -> Bool,
        onOpenOriginal: @escaping () -> Void = {},
        onClose: @escaping () -> Void = {}
    ) {
        let sourceDraft = initialDraft ?? CardEditDraft(card: card)
        self.card = card
        self.onSave = onSave
        self.onOpenOriginal = onOpenOriginal
        self.onClose = onClose
        originalDraft = CardEditDraft(card: card)
        _draft = State(initialValue: sourceDraft)
        _overlayState = State(initialValue: initialOverlay)
    }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                CardEditHeader(
                    isSaveEnabled: draft.isSavable,
                    onCancel: cancel,
                    onSave: save
                )
                editForm
            }

            overlay
        }
        .background(RecapTheme.ColorToken.background)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .task(id: overlayState) {
            await clearSaveFailureIfNeeded()
        }
    }

    private var editForm: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                CardEditOriginalPreview(card: card, onOpenOriginal: onOpenOriginal)

                CardEditTypeField(collection: $draft.collection)
                    .padding(.top, 23)

                CardEditTextFieldGroup(
                    title: "제목",
                    text: $draft.title,
                    limit: CardEditDraft.titleLimit,
                    placeholder: "텍스트",
                    showsRequiredError: draft.trimmedTitle.isEmpty
                )
                .padding(.top, 29)

                CardEditTextFieldGroup(
                    title: "한 줄 요약",
                    text: $draft.summary,
                    limit: CardEditDraft.summaryLimit,
                    placeholder: "텍스트",
                    showsRequiredError: draft.trimmedSummary.isEmpty
                )
                .padding(.top, 27)

                CardEditBodyField(body: $draft.body)
                    .padding(.top, 27)
            }
            .padding(.horizontal, CardDetailStyle.horizontalPadding)
            .padding(.bottom, 28)
        }
    }

    @ViewBuilder
    private var overlay: some View {
        switch overlayState {
        case .none:
            EmptyView()
        case .discardConfirmation:
            ZStack {
                CardDetailStyle.dim.ignoresSafeArea()
                RecapConfirmationDialog(
                    title: "수정을 그만둘까요?",
                    message: "저장하지 않은\n변경사항은 사라져요.",
                    cancelTitle: "계속 수정하기",
                    confirmTitle: "그만두기",
                    onCancel: { overlayState = .none },
                    onConfirm: close
                )
            }
        case .saveFailure:
            CardFeedbackToast(kind: .failure, message: "스크린샷 정보를 저장하지 못했어요. 다시 시도해주세요.")
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                .padding(.horizontal, 13)
                .padding(.bottom, 50)
        }
    }

    private func cancel() {
        if draft == originalDraft {
            close()
        } else {
            overlayState = .discardConfirmation
        }
    }

    private func save() {
        guard draft.isSavable else { return }
        if !onSave(draft) {
            overlayState = .saveFailure
        }
    }

    private func close() {
        onClose()
    }

    private func clearSaveFailureIfNeeded() async {
        guard overlayState == .saveFailure else { return }
        try? await Task.sleep(for: .seconds(2))
        guard !Task.isCancelled else { return }
        overlayState = .none
    }
}
