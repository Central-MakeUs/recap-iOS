import SwiftUI

struct CardDetailImageCard<Content: View>: View {
    let onExpand: () -> Void
    let content: Content

    init(
        onExpand: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.onExpand = onExpand
        self.content = content()
    }

    var body: some View {
        Button(action: onExpand) {
            content
                .frame(height: CardDetailStyle.imageCardHeight)
                .frame(maxWidth: .infinity)
                .clipped()
                .overlay(alignment: .bottomTrailing) {
                    CardExpandIcon()
                        .padding(.trailing, 8)
                        .padding(.bottom, 8)
                }
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: CardDetailStyle.cornerRadius,
                        style: .continuous
                    )
                )
                // 흰 스크린샷이 배경에 묻히지 않게 경계를 그린다 (07-01 수정 화면).
                .overlay {
                    RoundedRectangle(
                        cornerRadius: CardDetailStyle.cornerRadius,
                        style: .continuous
                    )
                    .strokeBorder(Color.recapGray100, lineWidth: 0.5)
                }
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("원본 이미지 전체 보기")
    }
}

#if DEBUG
#Preview("정보카드 이미지 카드") {
    CardDetailImageCard(onExpand: {}) {
        Color.gray
    }
    .padding(.horizontal, CardDetailStyle.horizontalPadding)
}
#endif
