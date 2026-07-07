import SwiftUI

struct ScreenHeader: View {
    enum Style {
        case logo
        case title(String)
    }

    let style: Style
    var showsMenu = true

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
    }
}

#Preview {
    VStack(spacing: RecapTheme.Spacing.large) {
        ScreenHeader(style: .logo)
        ScreenHeader(style: .title("컬렉션"), showsMenu: false)
    }
    .padding()
    .background(RecapTheme.ColorToken.background)
}
