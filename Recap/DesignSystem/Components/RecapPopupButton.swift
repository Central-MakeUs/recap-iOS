import SwiftUI

struct RecapPopupButton: View {
    enum Style {
        case secondary
        case primary
        case destructive

        var foregroundColor: Color {
            switch self {
            case .secondary:
                Color.recapGray700
            case .primary, .destructive:
                .white
            }
        }

        var backgroundColor: Color {
            switch self {
            case .secondary:
                Color.recapGray50
            case .primary:
                Color.recapBlue300
            case .destructive:
                Color.recapDestructive
            }
        }
    }

    let title: String
    let style: Style
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(RecapFont.pretendard(size: 14, weight: .semibold))
                .tracking(-0.28)
                .foregroundStyle(style.foregroundColor)
                .frame(maxWidth: .infinity)
                .frame(height: 45)
                .background(style.backgroundColor)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

#Preview("팝업 버튼") {
    HStack(spacing: 14) {
        RecapPopupButton(title: "취소", style: .secondary, action: {})
        RecapPopupButton(title: "삭제", style: .destructive, action: {})
    }
    .frame(width: 250)
}
