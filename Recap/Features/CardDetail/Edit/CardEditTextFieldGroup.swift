import SwiftUI

struct CardEditTextFieldGroup: View {
    let title: String
    @Binding var text: String
    let limit: Int
    let placeholder: String
    let showsRequiredError: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            CardEditFieldLabel(title: title)

            TextField(placeholder, text: limitedText)
                .font(RecapFont.pretendard(size: 14, weight: .regular))
                .tracking(-0.28)
                .foregroundStyle(Color.recapGray900)
                .padding(.horizontal, 12)
                .frame(height: 46)
                .cardEditFieldStyle()

            HStack(spacing: 5) {
                if showsRequiredError {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: 12, weight: .medium))
                    Text("필수 입력 항목입니다")
                        .font(RecapFont.pretendard(size: 12, weight: .medium))
                        .tracking(-0.24)
                }

                Spacer()

                Text("\(text.count)/\(limit)")
                    .font(RecapFont.pretendard(size: 12, weight: .medium))
                    .tracking(-0.24)
                    .foregroundStyle(Color.recapGray500)
            }
            .foregroundStyle(Color.recapDestructive)
        }
    }

    private var limitedText: Binding<String> {
        Binding(
            get: { text },
            set: { text = String($0.prefix(limit)) }
        )
    }
}

#Preview("정보카드 제목 입력") {
    @Previewable @State var title = "제주 숙소 예약 정보"
    CardEditTextFieldGroup(
        title: "제목",
        text: $title,
        limit: CardEditDraft.titleLimit,
        placeholder: "제목을 입력해주세요",
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
        placeholder: "제목을 입력해주세요",
        showsRequiredError: true
    )
    .padding()
}
