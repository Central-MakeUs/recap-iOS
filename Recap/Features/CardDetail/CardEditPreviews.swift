import SwiftUI

private extension SampleData {
    static var cardEditDraft: CardEditDraft {
        CardEditDraft(card: cards[1])
    }
}

#Preview("정보카드 수정") {
    CardEditScreen(card: SampleData.cards[1], initialDraft: SampleData.cardEditDraft, onSave: { _ in true })
}

#Preview("정보카드 수정 - 필수 입력 오류") {
    var draft = SampleData.cardEditDraft
    draft.title = ""
    return CardEditScreen(
        card: SampleData.cards[1],
        initialDraft: draft,
        onSave: { _ in true }
    )
}

#Preview("정보카드 수정 - 완료 비활성화") {
    var draft = SampleData.cardEditDraft
    draft.title = ""
    return CardEditScreen(
        card: SampleData.cards[1],
        initialDraft: draft,
        onSave: { _ in true }
    )
}

#Preview("정보카드 수정 - 타이핑") {
    var draft = SampleData.cardEditDraft
    draft.title = "텍스"
    return CardEditScreen(card: SampleData.cards[1], initialDraft: draft, onSave: { _ in true })
}

#Preview("정보카드 수정 - 저장 실패") {
    CardEditScreen(
        card: SampleData.cards[1],
        initialDraft: SampleData.cardEditDraft,
        initialOverlay: .saveFailure,
        onSave: { _ in false }
    )
}

#Preview("정보카드 수정 - 그만두기 확인") {
    CardEditScreen(
        card: SampleData.cards[1],
        initialDraft: SampleData.cardEditDraft,
        initialOverlay: .discardConfirmation,
        onSave: { _ in true }
    )
}
