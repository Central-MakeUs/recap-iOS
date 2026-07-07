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
            case .kakao, .secondary: RecapTheme.ColorToken.textPrimary
            }
        }

        var background: Color {
            switch self {
            case .primary: RecapTheme.ColorToken.primary
            case .dark: RecapTheme.ColorToken.textPrimary
            case .kakao: Color(red: 1.000, green: 0.895, blue: 0.200)
            case .secondary: RecapTheme.ColorToken.surface
            }
        }

        var border: Color {
            switch self {
            case .secondary: RecapTheme.ColorToken.border
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
                        .font(.subheadline.weight(.bold))
                }
                Text(title)
                    .font(.subheadline.weight(.bold))
            }
            .foregroundStyle(style.foreground)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(style.background)
            .clipShape(RoundedRectangle(cornerRadius: RecapTheme.Radius.medium, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: RecapTheme.Radius.medium, style: .continuous)
                    .stroke(style.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    VStack(spacing: RecapTheme.Spacing.medium) {
        RecapButton(title: "권한 허용하기", style: .primary) {}
        RecapButton(title: "카카오로 시작하기", systemImage: "message.fill", style: .kakao) {}
        RecapButton(title: "Apple로 시작하기", systemImage: "apple.logo", style: .dark) {}
    }
    .padding()
    .background(RecapTheme.ColorToken.background)
}
