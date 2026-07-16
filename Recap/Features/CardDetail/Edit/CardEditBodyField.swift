import SwiftUI

struct CardEditBodyField: View {
    @Binding var bodyText: String

    init(body: Binding<String>) {
        _bodyText = body
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            CardEditFieldLabel(title: "본문")

            TextEditor(text: limitedBody)
                .font(RecapFont.pretendard(size: 14, weight: .regular))
                .tracking(-0.28)
                .foregroundStyle(Color.recapGray900)
                .scrollContentBackground(.hidden)
                .padding(.horizontal, 7)
                .padding(.vertical, 6)
                .frame(height: 126)
                .cardEditFieldStyle()

            Text(String(format: "%03d/%03d", bodyText.count, CardEditDraft.bodyLimit))
                .font(RecapFont.pretendard(size: 12, weight: .medium))
                .tracking(-0.24)
                .foregroundStyle(Color.recapGray500)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }

    private var limitedBody: Binding<String> {
        Binding(
            get: { bodyText },
            set: { bodyText = String($0.prefix(CardEditDraft.bodyLimit)) }
        )
    }
}

#Preview("정보카드 본문 입력") {
    @Previewable @State var text = SampleData.cards[1].memo
    CardEditBodyField(body: $text)
        .padding()
}
