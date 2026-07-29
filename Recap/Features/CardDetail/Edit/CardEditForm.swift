import SwiftUI
import UIKit

struct CardEditForm: View {
    let card: InformationCard
    let onOpenOriginal: () -> Void
    @Binding var draft: CardEditDraft

    init(
        card: InformationCard,
        draft: Binding<CardEditDraft>,
        onOpenOriginal: @escaping () -> Void
    ) {
        self.card = card
        self.onOpenOriginal = onOpenOriginal
        _draft = draft
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                CardEditOriginalPreview(card: card, onOpenOriginal: onOpenOriginal)

                CardEditTypeField(collection: $draft.collection)
                    .padding(.top, 23)

                CardEditTextFieldGroup(
                    title: "제목",
                    text: $draft.title,
                    limit: CardEditDraft.titleLimit,
                    placeholder: "스크린샷 제목을 입력해주세요",
                    showsRequiredError: draft.trimmedTitle.isEmpty
                )
                .padding(.top, 29)

                CardEditTextFieldGroup(
                    title: "한 줄 요약",
                    text: $draft.summary,
                    limit: CardEditDraft.summaryLimit,
                    placeholder: "스크린샷을 한 줄로 요약해보세요",
                    showsRequiredError: draft.trimmedSummary.isEmpty
                )
                .padding(.top, 27)

                CardEditBodyField(
                    body: $draft.body,
                    showsRequiredError: draft.trimmedBody.isEmpty
                )
                    .padding(.top, 27)
            }
            .padding(.horizontal, CardDetailStyle.horizontalPadding)
            .padding(.bottom, 28)
            .background {
                Color.recapBackground
                    .contentShape(Rectangle())
                    .onTapGesture {
                        dismissKeyboard()
                    }
            }
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private func dismissKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }
}

#Preview("정보카드 수정 폼") {
    @Previewable @State var draft = CardEditDraft(card: SampleData.cards[1])

    CardEditForm(
        card: SampleData.cards[1],
        draft: $draft,
        onOpenOriginal: {}
    )
}
