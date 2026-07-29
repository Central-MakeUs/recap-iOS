import SwiftUI

struct CardEditBodyField: View {
    @Binding var bodyText: String

    init(body: Binding<String>) {
        _bodyText = body
    }

    var body: some View {
        RecapTextArea(
            label: "본문",
            text: $bodyText,
            placeholder: "스크린샷에 대한 설명을 작성해보세요",
            characterLimit: CardEditDraft.bodyLimit
        )
    }
}

#Preview("정보카드 본문 입력") {
    @Previewable @State var text = SampleData.cards[1].memo
    CardEditBodyField(body: $text)
        .padding()
}
