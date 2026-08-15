import SwiftUI

struct RecapFolderListRow: View {
    let title: String
    let subtitle: String
    let count: Int
    let kind: CardCategory

    var body: some View {
        HStack(spacing: 27) {
            RecapCategoryIcon(kind: kind, size: .medium)

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 8) {
                    Text(title)
                        .font(RecapFont.pretendard(size: 16, weight: .semibold))
                        .tracking(-0.32)
                        .foregroundStyle(Color.recapGray900)

                    Spacer(minLength: 0)

                    Text("\(count) Recaps")
                        .font(RecapFont.pretendard(size: 12, weight: .medium))
                        .tracking(-0.24)
                        .foregroundStyle(Color.recapGray300)
                }

                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(RecapFont.pretendard(size: 13, weight: .medium))
                        .tracking(-0.26)
                        .foregroundStyle(Color.recapGray500)
                        .lineLimit(1)
                }
            }
        }
        .padding(.horizontal, 20)
        .frame(height: 85)
        .background(Color.recapBackground)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.recapGray100)
                .frame(height: 1)
        }
    }
}

#if DEBUG
#Preview("폴더 목록 행") {
    VStack(spacing: 0) {
        RecapFolderListRow(
            title: "쇼핑 · 상품",
            subtitle: "택배 반품 절차 · 노트북 가격 비교",
            count: 12,
            kind: .shopping
        )

        RecapFolderListRow(
            title: "기타",
            subtitle: "",
            count: 0,
            kind: .other
        )
    }
}
#endif
