import SwiftUI

struct SearchBar: View {
    @Binding var text: String
    var placeholder = "스크린샷 내용이나 제목으로 검색"
    var showsClearButton = false
    var showsLeadingIcon = true

    var body: some View {
        HStack(spacing: 10) {
            if showsLeadingIcon {
                RecapIconView(icon: .search, size: 18, color: Color.recapGray300)
            }

            TextField(placeholder, text: $text)
                .font(RecapFont.pretendard(size: 13, weight: .medium))
                .tracking(-0.26)
                .foregroundStyle(Color.recapGray900)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

            if showsClearButton && !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    RecapIconView(icon: .cancel, size: 16, color: Color.recapGray300)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.leading, showsLeadingIcon ? 16 : 18)
        .padding(.trailing, 14)
        .frame(height: 44)
        .background(Color.recapControlFill)
        .clipShape(RoundedRectangle(cornerRadius: 44, style: .continuous))
    }
}

struct SearchBarDisplay: View {
    var placeholder = "스크린샷 내용이나 제목으로 검색"
    var showsLeadingIcon = true

    var body: some View {
        HStack(spacing: 10) {
            if showsLeadingIcon {
                RecapIconView(icon: .search, size: 18, color: Color.recapGray300)
            }

            Text(placeholder)
                .font(RecapFont.pretendard(size: 13, weight: .medium))
                .tracking(-0.26)
                .foregroundStyle(Color.recapGray300)

            Spacer(minLength: 0)
        }
        .padding(.leading, showsLeadingIcon ? 16 : 18)
        .padding(.trailing, 14)
        .frame(height: 44)
        .background(Color.recapControlFill)
        .clipShape(RoundedRectangle(cornerRadius: 44, style: .continuous))
    }
}

#Preview("Search bars") {
    ZStack {
        Color.recapBackground.ignoresSafeArea()
        VStack(spacing: RecapTheme.Spacing.medium) {
            SearchBar(text: .constant(""))
            SearchBarDisplay()
            SearchBar(text: .constant("숙소예약"), showsClearButton: true)
            SearchBar(text: .constant(""), showsLeadingIcon: false)
        }
        .padding()
    }
}
