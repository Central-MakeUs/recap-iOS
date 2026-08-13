import SwiftUI

struct CardEditView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(CardStore.self) private var cardStore

    let card: Card

    private let originalDraft: CardEditDraft
    private let saveAction: ((CardEditDraft) async throws -> Void)?
    private let closeAction: (() -> Void)?

    @State private var draft: CardEditDraft
    @State private var isDiscardConfirmationPresented: Bool
    @State private var toast: RecapToastContent?
    @State private var isOriginalPresented = false
    @State private var isSaving = false

    init(
        card: Card,
        initialDraft: CardEditDraft? = nil,
        initiallyShowsDiscardConfirmation: Bool = false,
        initialToast: RecapToastContent? = nil,
        onSave: ((CardEditDraft) async throws -> Void)? = nil,
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
                isSaveEnabled: draft.isSavable && !isSaving,
                onCancel: cancel,
                onSave: save
            )
            CardEditForm(
                card: card,
                draft: $draft,
                onOpenOriginal: showOriginal
            )
        }
        .background(Color.recapBackground)
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
        guard draft.isSavable, !isSaving else { return }
        isSaving = true

        Task {
            defer { isSaving = false }
            do {
                try await persist(draft)
                close()
            } catch {
                toast = RecapToastMessage.cardSaveFailed.content
            }
        }
    }

    private func persist(_ draft: CardEditDraft) async throws {
        if let saveAction {
            try await saveAction(draft.normalized())
            return
        }
        try await cardStore.saveEdit(draft.normalized(), for: card)
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

#if DEBUG
#Preview("정보카드 수정 화면") {
    NavigationStack {
        CardEditView(card: Card(snapshot: SampleData.cards[1]))
    }
    .environment(PreviewStores.cardStore())
}
#endif
