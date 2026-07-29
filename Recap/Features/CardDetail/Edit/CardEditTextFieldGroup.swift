import SwiftUI

struct CardEditTextFieldGroup: View {
    let title: String
    @Binding var text: String
    let limit: Int
    let placeholder: String
    let showsRequiredError: Bool

    var body: some View {
        RecapTextInput(
            label: title,
            text: $text,
            placeholder: placeholder,
            characterLimit: limit,
            errorMessage: showsRequiredError ? "필수 입력 항목입니다" : nil
        )
    }
}

#Preview("정보카드 제목 입력") {
    @Previewable @State var title = "제주 숙소 예약 정보"
    CardEditTextFieldGroup(
        title: "제목",
        text: $title,
        limit: CardEditDraft.titleLimit,
        placeholder: "스크린샷 제목을 입력해주세요",
        showsRequiredError: false
    )
    .padding()
}

#Preview("정보카드 필수 입력 오류") {
    @Previewable @State var title = ""
    CardEditTextFieldGroup(
        title: "제목",
        text: $title,
        limit: CardEditDraft.titleLimit,
        placeholder: "스크린샷 제목을 입력해주세요",
        showsRequiredError: true
    )
    .padding()
}
