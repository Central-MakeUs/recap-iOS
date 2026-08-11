import SwiftUI

struct SearchTopBar: View {
    @Binding var query: String
    let onSubmit: () -> Void
    let onClose: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            SearchBar(
                text: $query,
                placeholder: "제목, 요약, 이미지 속 내용으로 검색",
                showsClearButton: true,
                onSubmit: onSubmit
            )
            .frame(height: 44)

            Button("취소", action: onClose)
                .font(RecapFont.pretendard(size: 14, weight: .regular))
                .tracking(-0.28)
                .foregroundStyle(Color.recapGray500)
                .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 4)
    }
}

#if DEBUG
#Preview("검색 상단") {
    SearchTopBar(
        query: .constant(""),
        onSubmit: PreviewActions.noop,
        onClose: PreviewActions.noop
    )
    .background(Color.recapBackground)
}
#endif
