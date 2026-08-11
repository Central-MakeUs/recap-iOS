import SwiftUI

struct CardDetailNavigationBar: View {
    let title: String
    let isFavorite: Bool
    let foregroundColor: Color
    let onBack: () -> Void
    let onFavorite: () -> Void
    let onMore: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            Button(action: onBack) {
                RecapIconView(icon: .back, size: 24, color: foregroundColor)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .contentShape(Rectangle().inset(by: -10))
            .accessibilityLabel("뒤로가기")

            Text(title)
                .font(RecapFont.pretendard(size: 16, weight: .semibold))
                .tracking(-0.32)
                .foregroundStyle(foregroundColor)
                .padding(.leading, 13)
                .accessibilityAddTraits(.isHeader)

            Spacer(minLength: 0)

            Button(action: onFavorite) {
                RecapIconView(
                    icon: isFavorite ? .star : .starEmpty,
                    size: 24,
                    color: isFavorite
                        ? Color.recapBlue300
                        : foregroundColor.opacity(0.70)
                )
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .contentShape(Rectangle().inset(by: -5))
            .accessibilityLabel(isFavorite ? "즐겨찾기 해제" : "즐겨찾기 추가")

            Button(action: onMore) {
                RecapIconView(icon: .more, size: 24, color: foregroundColor)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .contentShape(Rectangle().inset(by: -5))
            .accessibilityLabel("더보기")
            .padding(.leading, 10)
        }
        .frame(height: 24)
        .padding(.horizontal, CardDetailStyle.horizontalPadding)
    }
}

#if DEBUG
#Preview("정보카드 상세 내비게이션") {
    ZStack(alignment: .top) {
        Color.gray

        CardDetailNavigationBar(
            title: "스크린샷 상세",
            isFavorite: false,
            foregroundColor: .white,
            onBack: {},
            onFavorite: {},
            onMore: {}
        )
        .padding(.top, 20)
    }
    .frame(height: 64)
}
#endif
