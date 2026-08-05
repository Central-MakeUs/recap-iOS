import SwiftUI

struct RecapPopupButton: View {
    enum Style {
        case secondary
        case primary
        case destructive

        var foregroundColor: Color {
            switch self {
            case .secondary:
                Color("RecapGray700")
            case .primary, .destructive:
                .white
            }
        }

        var backgroundColor: Color {
            switch self {
            case .secondary:
                Color("RecapGray50")
            case .primary:
                Color("RecapBlue300")
            case .destructive:
                Color("RecapDestructive")
            }
        }
    }

    let title: String
    let style: Style
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.custom("Pretendard-SemiBold", size: 14))
                .tracking(-0.28)
        }
        .buttonStyle(RecapPopupButtonStyle(style: style))
    }
}

private struct RecapPopupButtonStyle: ButtonStyle {
    let style: RecapPopupButton.Style

    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(isEnabled ? style.foregroundColor : Color("RecapGray300"))
            .frame(maxWidth: .infinity)
            .frame(height: 45)
            .background {
                if isEnabled {
                    style.backgroundColor
                        .overlay {
                            if configuration.isPressed {
                                Color.black.opacity(0.12)
                            }
                        }
                } else {
                    Color("RecapGray100")
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

#Preview("popup buttons") {
    HStack(spacing: 14) {
        RecapPopupButton(title: "취소", style: .secondary, action: {})
        RecapPopupButton(title: "삭제", style: .destructive, action: {})
    }
    .frame(width: 250)
}
