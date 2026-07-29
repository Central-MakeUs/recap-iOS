import SwiftUI

struct CardEditBodyField: View {
    @Binding var bodyText: String
    let showsRequiredError: Bool

    init(body: Binding<String>, showsRequiredError: Bool) {
        _bodyText = body
        self.showsRequiredError = showsRequiredError
    }

    var body: some View {
        RecapTextArea(
            label: "본문",
            text: $bodyText,
            placeholder: "스크린샷에 대한 설명을 작성해보세요",
            characterLimit: CardEditDraft.bodyLimit,
            errorMessage: showsRequiredError ? "필수 입력 항목입니다" : nil
        )
    }
}

#Preview("정보카드 본문 입력 - 짧은 본문") {
    @Previewable @State var text = "논현손칼국수: 언주역 최애 칼국수집. 사리 추가·공기밥 추가 무료"
    CardEditBodyField(body: $text, showsRequiredError: false)
        .padding()
}

#Preview("정보카드 본문 입력 - 긴 본문") {
    @Previewable @State var text = String(
        repeating: "스크린샷에 담긴 내용을 자세히 설명하는 긴 본문입니다. ",
        count: 14
    )
    CardEditBodyField(body: $text, showsRequiredError: false)
        .padding()
}
