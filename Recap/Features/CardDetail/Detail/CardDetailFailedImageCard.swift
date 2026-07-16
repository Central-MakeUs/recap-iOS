import SwiftUI

struct CardDetailFailedImageCard: View {
    let onExpand: () -> Void

    var body: some View {
        CardDetailImageCard(onExpand: onExpand) {
            ZStack {
                Color.recapImageFailureFill
                CardImageFailureView()
            }
        }
        .padding(.horizontal, CardDetailStyle.horizontalPadding)
    }
}

#Preview("정보카드 이미지 카드 로딩 실패") {
    CardDetailFailedImageCard(onExpand: {})
}
