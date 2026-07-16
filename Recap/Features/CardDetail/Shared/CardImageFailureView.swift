import SwiftUI

struct CardImageFailureView: View {
    var body: some View {
        VStack(spacing: 7) {
            Image(systemName: "photo.badge.exclamationmark")
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(RecapTheme.ColorToken.textTertiary)
                .frame(width: 24, height: 24)

            Text("원본 이미지를 불러오지 못했어요")
                .font(RecapFont.pretendard(size: 14, weight: .regular))
                .tracking(-0.28)
                .foregroundStyle(RecapTheme.ColorToken.textTertiary)
        }
    }
}

#Preview("원본 이미지 불러오기 실패") {
    CardImageFailureView()
        .frame(width: 361, height: 184)
        .background(CardDetailStyle.imageFailureFill)
}
