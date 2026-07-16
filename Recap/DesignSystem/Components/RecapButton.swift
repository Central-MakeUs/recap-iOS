import SwiftUI

struct RecapButton: View {
    enum Style {
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
            case .secondary: Color.white
            }
        }

        var border: Color {
            switch self {
            case .secondary: Color.recapGray100
            case .primary, .dark, .kakao: .clear
            }
        }
    }

    let title: String
    var systemImage: String? = nil
    var style: Style = .primary
    let action: () -> Void

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
            .foregroundStyle(style.foreground)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(style.background)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(style.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
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
            RecapButton(title: "카카오로 로그인", systemImage: "message.fill", style: .kakao, action: PreviewActions.noop)
            RecapButton(title: "Apple로 시작하기", systemImage: "apple.logo", style: .dark, action: PreviewActions.noop)
        }
        .padding()
    }
}
