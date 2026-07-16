import SwiftUI

struct CardEditView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(RecapCardStore.self) private var cardStore

    let card: InformationCard

    private let originalDraft: CardEditDraft
    private let saveAction: ((CardEditDraft) -> Bool)?
    private let closeAction: (() -> Void)?

    @State private var draft: CardEditDraft
    @State private var isDiscardConfirmationPresented: Bool
    @State private var toast: RecapToastContent?
    @State private var isOriginalPresented = false

    init(
        card: InformationCard,
        initialDraft: CardEditDraft? = nil,
        initiallyShowsDiscardConfirmation: Bool = false,
        initialToast: RecapToastContent? = nil,
        onSave: ((CardEditDraft) -> Bool)? = nil,
        onClose: (() -> Void)? = nil
    ) {
        let sourceDraft = initialDraft ?? CardEditDraft(card: card)
        self.card = card
        originalDraft = CardEditDraft(card: card)
        saveAction = onSave
        closeAction = onClose
        _draft = State(initialValue: sourceDraft)
        _isDiscardConfirmationPresented = State(initialValue: initiallyShowsDiscardConfirmation)
        _toast = State(initialValue: initialToast)
    }

    var body: some View {
        VStack(spacing: 0) {
            CardEditHeader(
                isSaveEnabled: draft.isSavable,
                onCancel: cancel,
                onSave: save
            )
            CardEditForm(
                card: card,
                draft: $draft,
                onOpenOriginal: showOriginal
            )
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
        .recapToast(toast)
        .task(id: toast) {
            await clearToastIfNeeded()
        }
        .fullScreenCover(isPresented: $isOriginalPresented) {
            CardOriginalPreviewSheet(card: card)
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
        guard persist(draft) else {
            toast = RecapToastContent(
                style: .error,
                message: "스크린샷 정보를 저장하지 못했어요. 다시 시도해주세요."
            )
            return
        }
        close()
    }

    private func persist(_ draft: CardEditDraft) -> Bool {
        if let saveAction {
            return saveAction(draft)
        }
        cardStore.updateCard(id: card.id, with: draft.normalized())
        return true
    }

    private func close() {
        if let closeAction {
            closeAction()
        } else {
            dismiss()
        }
    }

    private func showOriginal() {
        isOriginalPresented = true
    }

    private func clearToastIfNeeded() async {
        guard toast != nil else { return }
        try? await Task.sleep(for: .seconds(2))
        guard !Task.isCancelled else { return }
        toast = nil
    }
}

#Preview("정보카드 수정 화면") {
    NavigationStack {
        CardEditView(card: SampleData.cards[1])
    }
    .environment(PreviewStores.recapCardStore())
}
