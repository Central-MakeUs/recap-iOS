import SwiftUI

struct RecapTextInput: View {
    let label: String
    @Binding var text: String
    var placeholder: String
    var characterLimit: Int?
    var errorMessage: String?

    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(RecapFont.pretendard(size: 13, weight: .medium))
                .tracking(-0.26)
                .foregroundStyle(Color.recapGray900)

            TextField(placeholder, text: limitedText)
                .focused($isFocused)
                .font(RecapFont.pretendard(size: 14, weight: .regular))
                .tracking(-0.28)
                .foregroundStyle(Color.recapGray900)
                .padding(.horizontal, 13)
                .frame(height: 46)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(isFocused ? Color.recapBlue300 : Color.recapGray200, lineWidth: 1)
                }

            if characterLimit != nil || errorMessage != nil {
                HStack(spacing: 6) {
                    if let errorMessage {
                        Image(systemName: "exclamationmark.circle.fill")
                            .font(.system(size: 12, weight: .medium))
                        Text(errorMessage)
                            .font(RecapFont.pretendard(size: 12, weight: .medium))
                            .tracking(-0.24)
                    }

                    Spacer(minLength: 0)

                    if let characterLimit {
                        RecapCharacterCounter(
                            currentCount: text.count,
                            limit: characterLimit
                        )
                    }
                }
                .foregroundStyle(Color.recapDestructive)
            }
        }
    }

    private var limitedText: Binding<String> {
        Binding(
            get: { text },
            set: { value in
                text = characterLimit.map { String(value.prefix($0)) } ?? value
            }
        )
    }
}

struct RecapTextArea: View {
    let label: String
    @Binding var text: String
    var placeholder: String
    var characterLimit: Int?

    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            RecapInputLabel(title: label)

            TextEditor(text: limitedText)
                .focused($isFocused)
                .font(RecapFont.pretendard(size: 14, weight: .regular))
                .tracking(-0.28)
                .foregroundStyle(Color.recapGray900)
                .scrollContentBackground(.hidden)
                .overlay(alignment: .topLeading) {
                    if text.isEmpty {
                        Text(placeholder)
                            .font(RecapFont.pretendard(size: 14, weight: .regular))
                            .tracking(-0.28)
                            .foregroundStyle(Color.recapGray300)
                            .padding(.top, 8)
                            .padding(.leading, 5)
                            .allowsHitTesting(false)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .frame(height: 126)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(isFocused ? Color.recapBlue300 : Color.recapGray200, lineWidth: 1)
                }

            if let characterLimit {
                RecapCharacterCounter(
                    currentCount: text.count,
                    limit: characterLimit
                )
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
    }

    private var limitedText: Binding<String> {
        Binding(
            get: { text },
            set: { value in
                text = characterLimit.map { String(value.prefix($0)) } ?? value
            }
        )
    }
}

struct RecapActionInput: View {
    let label: String
    let value: String
    let actionTitle: String
    let action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            RecapInputLabel(title: label)

            Button(action: action) {
                HStack {
                    Text(value)
                        .foregroundStyle(Color.recapGray900)

                    Spacer()

                    Text(actionTitle)
                        .foregroundStyle(Color.recapBlue500)
                }
                .font(RecapFont.pretendard(size: 14, weight: .regular))
                .tracking(-0.28)
                .padding(.horizontal, 13)
                .frame(height: 46)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color.recapGray200, lineWidth: 1)
                }
            }
            .buttonStyle(.plain)
        }
    }
}

private struct RecapInputLabel: View {
    let title: String

    var body: some View {
        Text(title)
            .font(RecapFont.pretendard(size: 13, weight: .medium))
            .tracking(-0.26)
            .foregroundStyle(Color.recapGray900)
    }
}

private struct RecapCharacterCounter: View {
    let currentCount: Int
    let limit: Int

    var body: some View {
        let currentText = Text("\(currentCount)")
            .font(RecapFont.pretendard(size: 12, weight: .bold))
            .foregroundStyle(Color.recapGray900)
        let limitText = Text("/\(limit)")
            .font(RecapFont.pretendard(size: 12, weight: .medium))
            .foregroundStyle(Color.recapGray300)

        Text("\(currentText)\(limitText)")
            .tracking(-0.24)
    }
}

#Preview("입력 필드") {
    @Previewable @State var text = "제주 숙소 예약 정보"

    VStack(spacing: 24) {
        RecapTextInput(
            label: "제목",
            text: $text,
            placeholder: "제목을 입력해주세요",
            characterLimit: 30
        )
        RecapTextInput(
            label: "제목",
            text: .constant(""),
            placeholder: "제목을 입력해주세요",
            characterLimit: 30,
            errorMessage: "필수 입력 항목입니다"
        )
        RecapTextArea(
            label: "본문",
            text: $text,
            placeholder: "본문을 입력해주세요",
            characterLimit: 300
        )
        RecapActionInput(
            label: "유형",
            value: "일정 · 예약",
            actionTitle: "변경",
            action: {}
        )
    }
    .padding()
}
