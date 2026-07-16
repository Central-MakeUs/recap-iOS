import SwiftUI

enum RecapIcon: String, CaseIterable, Identifiable {
    case star
    case cancel
    case back
    case search
    case home
    case storage
    case plus
    case more
    case dropdown

    var id: String { rawValue }

    var systemName: String {
        switch self {
        case .star: "star.fill"
        case .cancel: "xmark.circle.fill"
        case .back: "chevron.left"
        case .search: "magnifyingglass"
        case .home: "house"
        case .storage: "tray.full"
        case .plus: "plus"
        case .more: "ellipsis"
        case .dropdown: "chevron.down"
        }
    }

    var figmaName: String {
        switch self {
        case .star: "icon/star"
        case .cancel: "icon/cancel"
        case .back: "icon/back"
        case .search: "icon/search"
        case .home: "icon/home"
        case .storage: "icon/storage"
        case .plus: "icon/plus"
        case .more: "icon/more"
        case .dropdown: "icon/dropdown"
        }
    }

    var defaultSize: CGFloat {
        switch self {
        case .cancel: 20
        case .plus: 30
        case .dropdown: 16
        case .star, .back, .search, .home, .storage, .more: 24
        }
    }

    var symbolScale: CGFloat {
        switch self {
        case .cancel: 1.00
        case .plus: 0.62
        case .dropdown: 0.68
        case .more: 0.78
        case .back: 0.78
        case .search: 0.82
        case .home, .storage: 0.86
        case .star: 0.92
        }
    }

    var defaultWeight: Font.Weight {
        switch self {
        case .plus, .back, .dropdown: .semibold
        case .cancel, .star, .home, .storage, .more, .search: .regular
        }
    }
}

struct RecapIconView: View {
    let icon: RecapIcon
    var size: CGFloat? = nil
    var color: Color = Color.recapGray900
    var weight: Font.Weight? = nil

    private var resolvedSize: CGFloat { size ?? icon.defaultSize }
    private var resolvedWeight: Font.Weight { weight ?? icon.defaultWeight }

    var body: some View {
        Image(systemName: icon.systemName)
            .font(.system(size: resolvedSize * icon.symbolScale, weight: resolvedWeight))
            .foregroundStyle(color)
            .frame(width: resolvedSize, height: resolvedSize)
            .accessibilityLabel(icon.figmaName)
    }
}

#Preview("Recap icons") {
    ZStack {
        Color.recapBackground.ignoresSafeArea()
        HStack(spacing: RecapTheme.Spacing.medium) {
            ForEach(RecapIcon.allCases) { icon in
                RecapIconView(icon: icon)
            }
        }
        .padding()
    }
}
