import SwiftUI

struct CardEditView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(RecapCardStore.self) private var cardStore

    let card: InformationCard

    @State private var isOriginalPresented = false

    var body: some View {
        CardEditScreen(
            card: card,
            onSave: save,
            onOpenOriginal: showOriginal,
            onClose: dismiss.callAsFunction
        )
        .fullScreenCover(isPresented: $isOriginalPresented) {
            CardOriginalPreviewSheet(card: card)
        }
    }

    private func save(_ draft: CardEditDraft) -> Bool {
        cardStore.updateCard(id: card.id, with: draft.normalized())
        dismiss()
        return true
    }

    private func showOriginal() {
        isOriginalPresented = true
    }
}

struct CardEditScreen: View {
    let card: InformationCard
    let onSave: (CardEditDraft) -> Bool
    let onOpenOriginal: () -> Void
    let onClose: () -> Void

    @State private var draft: CardEditDraft
    @State private var isDiscardConfirmationPresented: Bool
    @State private var feedback: CardFeedback?

    private let originalDraft: CardEditDraft

    init(
        card: InformationCard,
        initialDraft: CardEditDraft? = nil,
        initiallyShowsDiscardConfirmation: Bool = false,
        initialFeedback: CardFeedback? = nil,
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
        _isDiscardConfirmationPresented = State(initialValue: initiallyShowsDiscardConfirmation)
        _feedback = State(initialValue: initialFeedback)
    }

    var body: some View {
        VStack(spacing: 0) {
            CardEditHeader(
                isSaveEnabled: draft.isSavable,
                onCancel: cancel,
                onSave: save
            )
            editForm
        }
        .background(RecapTheme.ColorToken.background)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .recapConfirmationDialog(
            isPresented: $isDiscardConfirmationPresented,
            title: "수정을 그만둘까요?",
            message: "저장하지 않은\n변경사항은 사라져요.",
            cancelTitle: "계속 수정하기",
            confirmTitle: "그만두기",
            onConfirm: close
        )
        .cardFeedbackToast(feedback, horizontalPadding: 13, bottomPadding: 50)
        .task(id: feedback) {
            await clearFeedbackIfNeeded()
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

    private func cancel() {
        if draft == originalDraft {
            close()
        } else {
            isDiscardConfirmationPresented = true
        }
    }

    private func save() {
        guard draft.isSavable else { return }
        if !onSave(draft) {
            feedback = CardFeedback(
                kind: .failure,
                message: "스크린샷 정보를 저장하지 못했어요. 다시 시도해주세요."
            )
        }
    }

    private func close() {
        onClose()
    }

    private func clearFeedbackIfNeeded() async {
        guard feedback != nil else { return }
        try? await Task.sleep(for: .seconds(2))
        guard !Task.isCancelled else { return }
        feedback = nil
    }
}
