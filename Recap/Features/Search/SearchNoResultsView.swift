import SwiftUI

struct SearchNoResultsView: View {
    var body: some View {
        VStack(spacing: 0) {
            SearchNoResultsIllustration()

            Text("검색 결과가 없어요")
                .font(RecapFont.pretendard(size: 16, weight: .semibold))
                .tracking(-0.32)
                .foregroundStyle(Color.recapGray300)
                .padding(.top, 26)

            Text("다른 키워드로 다시 검색해보세요")
                .font(RecapFont.pretendard(size: 14, weight: .regular))
                .tracking(-0.28)
                .foregroundStyle(Color.recapGray300)
                .padding(.top, 13)

            Spacer(minLength: 0)
        }
        .padding(.top, 208)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct SearchNoResultsIllustration: View {
    var body: some View {
        Image("SearchEmptyIllustration")
            .resizable()
            .scaledToFit()
            .frame(width: 123, height: 83, alignment: .topLeading)
            .accessibilityHidden(true)
    }
}

#Preview("검색 결과 없음") {
    SearchNoResultsView()
        .background(Color.recapBackground)
}
