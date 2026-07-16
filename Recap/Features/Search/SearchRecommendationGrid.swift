import SwiftUI

struct SearchRecommendationGrid: View {
    private let recommendations = Array(repeating: "정리된 제목", count: 6)

    var body: some View {
        VStack(alignment: .leading, spacing: 28) {
            HStack(spacing: 6) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color.recapWarning)
                    .frame(width: 24, height: 24)

                Text("이런 내용까지 검색가능해요!")
                    .font(RecapFont.pretendard(size: 13, weight: .medium))
                    .tracking(-0.26)
                    .foregroundStyle(Color.recapGray700)
            }

            VStack(spacing: 24) {
                ForEach(0..<3, id: \.self) { row in
                    HStack(spacing: 99) {
                        recommendationItem(recommendations[row * 2])
                        recommendationItem(recommendations[row * 2 + 1])
                    }
                }
            }
            .padding(.leading, 4)
        }
    }

    private func recommendationItem(_ title: String) -> some View {
        HStack(spacing: 10) {
            Rectangle()
                .fill(Color.recapThumbnail)
                .frame(width: 16, height: 16)
            Text(title)
                .font(RecapFont.pretendard(size: 13, weight: .medium))
                .tracking(-0.26)
                .foregroundStyle(Color.recapGray500)
        }
        .frame(width: 89, height: 18, alignment: .leading)
    }
}
