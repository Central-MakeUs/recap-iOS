#if DEBUG
import SwiftUI

private extension SampleData {
    @MainActor
    static var cardEditCard: Card {
        Card(snapshot: cards[1])!
    }

    @MainActor
    static var cardEditDraft: CardEditDraft {
        CardEditDraft(card: cardEditCard)
    }
}

#Preview("정보카드 수정") {
    CardEditView(
        card: SampleData.cardEditCard,
        initialDraft: SampleData.cardEditDraft,
        onSave: { _ in }
    )
    .environment(PreviewStores.cardStore())
}

#Preview("정보카드 수정 - 필수 입력 오류") {
    var draft = SampleData.cardEditDraft
    draft.title = ""
    return CardEditView(
        card: SampleData.cardEditCard,
        initialDraft: draft,
        onSave: { _ in }
    )
    .environment(PreviewStores.cardStore())
}

#Preview("정보카드 수정 - 완료 비활성화") {
    var draft = SampleData.cardEditDraft
    draft.title = ""
    return CardEditView(
        card: SampleData.cardEditCard,
        initialDraft: draft,
        onSave: { _ in }
    )
    .environment(PreviewStores.cardStore())
}

#Preview("정보카드 수정 - 타이핑") {
    var draft = SampleData.cardEditDraft
    draft.title = "텍스"
    return CardEditView(
        card: SampleData.cardEditCard,
        initialDraft: draft,
        onSave: { _ in }
    )
    .environment(PreviewStores.cardStore())
}

#Preview("정보카드 수정 - 저장 실패") {
    CardEditView(
        card: SampleData.cardEditCard,
        initialDraft: SampleData.cardEditDraft,
        initialToast: RecapToastContent(
            style: .error,
            message: "스크린샷 정보를 저장하지 못했어요. 다시 시도해주세요."
        ),
        onSave: { _ in throw APIError.offline }
    )
    .environment(PreviewStores.cardStore())
}

#Preview("정보카드 수정 - 그만두기 확인") {
    CardEditView(
        card: SampleData.cardEditCard,
        initialDraft: SampleData.cardEditDraft,
        initiallyShowsDiscardConfirmation: true,
        onSave: { _ in }
    )
    .environment(PreviewStores.cardStore())
}
#endif
