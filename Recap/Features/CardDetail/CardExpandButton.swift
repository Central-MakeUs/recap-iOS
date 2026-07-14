import SwiftUI

struct CardExpandButton: View {
    var foregroundColor: Color = .white
    var backgroundColor: Color = .black.opacity(0.28)
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "arrow.up.left.and.arrow.down.right")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(foregroundColor)
                .frame(width: 21, height: 21)
                .background(backgroundColor)
                .overlay {
                    RoundedRectangle(cornerRadius: 2)
                        .stroke(CardDetailStyle.inputBorder, lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("원본 이미지 전체 보기")
    }
}

#Preview("원본 이미지 확장 버튼") {
    CardExpandButton(action: {})
        .padding(20)
        .background(Color.gray)
}
