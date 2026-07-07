import SwiftUI

struct ScreenHeader: View {
    enum Style {
        case logo
        case title(String)
    }

    let style: Style
    var showsMenu = true
    var onMenuTap: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: RecapTheme.Spacing.medium) {
            switch style {
            case .logo:
                RecapLogo()
            case .title(let title):
                Text(title)
                    .font(.title3.weight(.black))
                    .foregroundStyle(RecapTheme.ColorToken.textPrimary)
            }

            Spacer()

            if showsMenu {
                if let onMenuTap {
                    Button(action: onMenuTap) {
                        menuIcon
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("설정 열기")
                } else {
                    menuIcon
                        .accessibilityHidden(true)
                }
            }
        }
    }

    private var menuIcon: some View {
        Image(systemName: "ellipsis")
            .rotationEffect(.degrees(90))
            .font(.subheadline.weight(.bold))
            .foregroundStyle(RecapTheme.ColorToken.textSecondary)
            .frame(width: 32, height: 32)
            .background(RecapTheme.ColorToken.surface)
            .clipShape(RoundedRectangle(cornerRadius: RecapTheme.Radius.small, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: RecapTheme.Radius.small, style: .continuous)
                    .stroke(RecapTheme.ColorToken.border, lineWidth: 1)
            )
    }
}

#Preview {
    ZStack {
        RecapTheme.ColorToken.background.ignoresSafeArea()
        VStack(spacing: RecapTheme.Spacing.large) {
            ScreenHeader(style: .logo)
            ScreenHeader(style: .title("컬렉션"), showsMenu: false)
        }
        .padding()
    }
}
