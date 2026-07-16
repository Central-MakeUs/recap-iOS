import SwiftUI

struct RecapButton: View {
    enum Size {
        case large
        case medium
        case small

        var height: CGFloat {
            switch self {
            case .large: 50
            case .medium: 45
            case .small: 40
            }
        }
    }

    enum Style: Equatable {
        case primary
        case dark
        case kakao
        case secondary

        var foreground: Color {
            switch self {
            case .primary, .dark: .white
            case .kakao: Color.recapGray900
            case .secondary: Color.recapBlue300
            }
        }

        var background: Color {
            switch self {
            case .primary: Color.recapBlue300
            case .dark: Color.recapGray900
            case .kakao: Color.recapKakaoYellow
            case .secondary: Color.recapPrimarySoft
            }
        }

    }

    let title: String
    var systemImage: String?
    var style: Style = .primary
    var size: Size = .large
    let action: () -> Void

    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        Button(action: action) {
            HStack(spacing: RecapTheme.Spacing.small) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 16, weight: .semibold))
                }
                Text(title)
                    .font(RecapFont.pretendard(size: 14, weight: .semibold))
                    .tracking(-0.28)
            }
            .frame(maxWidth: .infinity)
            .frame(height: size.height)
        }
        .foregroundStyle(isEnabled ? style.foreground : Color.recapGray300)
        .buttonStyle(RecapButtonPressStyle(style: style, isEnabled: isEnabled))
    }
}

private struct RecapButtonPressStyle: ButtonStyle {
    let style: RecapButton.Style
    let isEnabled: Bool

    func makeBody(configuration: Configuration) -> some View {
        let background = if !isEnabled {
            Color.recapGray100
        } else if configuration.isPressed && style == .primary {
            Color.recapBlue500
        } else {
            style.background
        }

        configuration.label
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .opacity(configuration.isPressed && isEnabled && style != .primary ? 0.82 : 1)
    }
}

struct RecapIconButtonLarge: View {
    let title: String
    var systemImage: String
    var style: RecapButton.Style = .kakao
    let action: () -> Void

    var body: some View {
        RecapButton(title: title, systemImage: systemImage, style: style, action: action)
    }
}

#Preview {
    ZStack {
        Color.recapBackground.ignoresSafeArea()
        VStack(spacing: RecapTheme.Spacing.medium) {
            RecapButton(title: "버튼", style: .primary, action: PreviewActions.noop)
            RecapButton(title: "버튼", style: .secondary, size: .medium, action: PreviewActions.noop)
                .frame(width: 155)
            RecapButton(title: "버튼", style: .primary, size: .small, action: PreviewActions.noop)
                .frame(width: 125)
            RecapButton(title: "비활성 버튼", style: .primary, action: PreviewActions.noop)
                .disabled(true)
            RecapButton(title: "카카오로 로그인", systemImage: "message.fill", style: .kakao, action: PreviewActions.noop)
            RecapButton(title: "Apple로 시작하기", systemImage: "apple.logo", style: .dark, action: PreviewActions.noop)
        }
        .padding()
    }
}
