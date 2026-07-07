import SwiftUI

struct SearchBar: View {
    @Binding var text: String
    var placeholder = "카드 제목 또는 핵심 정보 검색"
    var showsClearButton = false

    var body: some View {
        HStack(spacing: RecapTheme.Spacing.small) {
            Image(systemName: "magnifyingglass")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(RecapTheme.ColorToken.textTertiary)

            TextField(placeholder, text: $text)
                .font(.subheadline)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

            if showsClearButton && !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(RecapTheme.ColorToken.textTertiary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, RecapTheme.Spacing.medium)
        .frame(height: 40)
        .recapCard(radius: RecapTheme.Radius.medium)
    }
}

#Preview {
    VStack {
        SearchBar(text: .constant(""))
        SearchBar(text: .constant("성수동"), showsClearButton: true)
    }
    .padding()
    .background(RecapTheme.ColorToken.background)
}
