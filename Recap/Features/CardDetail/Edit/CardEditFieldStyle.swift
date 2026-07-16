import SwiftUI

struct CardEditFieldLabel: View {
    let title: String

    var body: some View {
        Text(title)
            .font(RecapFont.pretendard(size: 13, weight: .medium))
            .tracking(-0.26)
            .foregroundStyle(RecapTheme.ColorToken.textPrimary)
    }
}

extension View {
    func cardEditFieldStyle() -> some View {
        background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(CardDetailStyle.inputBorder, lineWidth: 1)
            }
    }
}

#Preview("정보카드 입력 필드 라벨") {
    CardEditFieldLabel(title: "제목")
        .padding()
}
