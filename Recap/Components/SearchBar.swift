import SwiftUI

struct SearchBar: View {
    @Binding var text: String
    var placeholder = "이 컬렉션 내에서 검색"
    var showsClearButton = false
    var showsLeadingIcon = false

    var body: some View {
        HStack(spacing: RecapTheme.Spacing.small) {
            if showsLeadingIcon {
                RecapIconView(icon: .search, size: 24, color: RecapTheme.ColorToken.textTertiary)
            }

            TextField(placeholder, text: $text)
                .font(.system(size: 13, weight: .medium))
                .tracking(-0.26)
                .foregroundStyle(RecapTheme.ColorToken.textPrimary)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

            if showsClearButton && !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    RecapIconView(icon: .cancel, size: 20, color: RecapTheme.ColorToken.textTertiary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.leading, showsLeadingIcon ? RecapTheme.Spacing.medium : 44)
        .padding(.trailing, RecapTheme.Spacing.medium)
        .frame(height: 44)
        .background(RecapComponentColor.controlFill)
        .clipShape(RoundedRectangle(cornerRadius: 44, style: .continuous))
    }
}

#Preview {
    ZStack {
        Color.green.ignoresSafeArea()
        VStack {
            SearchBar(text: .constant(""))
            SearchBar(text: .constant("성수동"), showsClearButton: true)
            SearchBar(text: .constant(""), placeholder: "카드 제목 또는 핵심 정보 검색", showsLeadingIcon: true)
        }
    }
}
