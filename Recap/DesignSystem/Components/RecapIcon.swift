import SwiftUI

enum RecapIcon: String, CaseIterable, Identifiable {
    case star
    case starEmpty
    case cancel
    case cancelCircle
    case back
    case forward
    case search
    case home
    case storage
    case plus
    case more
    case dropdown
    case checkbox
    case setting
    case information
    case grid
    case list
    case error
    case success
    case shopping
    case place
    case schedule
    case idea
    case book
    case event
    case record
    case noImage
    case check

    var id: String { rawValue }

    var systemName: String {
        switch self {
        case .star: "star.fill"
        case .starEmpty: "star"
        case .cancel: "xmark"
        case .cancelCircle: "xmark.circle.fill"
        case .back: "chevron.left"
        case .forward: "chevron.right"
        case .search: "magnifyingglass"
        case .home: "house.fill"
        case .storage: "archivebox.fill"
        case .plus: "plus"
        case .more: "ellipsis"
        case .dropdown: "chevron.down"
        case .checkbox: "checkmark.square.fill"
        case .setting: "gearshape"
        case .information: "info.bubble.fill"
        case .grid: "square.grid.2x2.fill"
        case .list: "list.bullet"
        case .error: "exclamationmark.circle.fill"
        case .success: "checkmark.circle.fill"
        case .shopping: "cart.fill"
        case .place: "key.fill"
        case .schedule: "clock.fill"
        case .idea: "lightbulb.fill"
        case .book: "book.closed.fill"
        case .event: "star.fill"
        case .record: "pencil"
        case .noImage: "photo"
        case .check: "checkmark"
        }
    }

    var figmaName: String {
        switch self {
        case .star: "icon/star/selected"
        case .starEmpty: "icon/star/empty"
        case .cancel: "icon/cancel"
        case .cancelCircle: "icon/cancelcircle"
        case .back: "icon/back"
        case .forward: "icon/rightback"
        case .search: "icon/search"
        case .home: "icon/home"
        case .storage: "icon/storage"
        case .plus: "icon/plus"
        case .more: "icon/more"
        case .dropdown: "icon/dropdown"
        case .checkbox: "icon/checkbox"
        case .setting: "icon/setting"
        case .information: "icon/infomessage"
        case .grid: "icon/grid"
        case .list: "icon/list"
        case .error: "icon/error"
        case .success: "icon/success"
        case .shopping: "icon/shopping"
        case .place: "icon/place"
        case .schedule: "icon/schedule"
        case .idea: "icon/idea"
        case .book: "icon/book"
        case .event: "icon/event"
        case .record: "icon/record"
        case .noImage: "icon/noimage"
        case .check: "icon/check"
        }
    }

    var defaultSize: CGFloat {
        switch self {
        case .cancelCircle, .dropdown, .checkbox, .shopping, .place, .schedule, .idea, .book, .event, .record:
            16
        case .plus: 30
        case .star, .starEmpty, .cancel, .back, .forward, .search, .home, .storage, .more,
             .setting, .information, .grid, .list, .error, .success, .noImage, .check:
            24
        }
    }

    var symbolScale: CGFloat {
        switch self {
        case .cancelCircle: 1.00
        case .plus: 0.62
        case .dropdown: 0.68
        case .more: 0.78
        case .back, .forward: 0.78
        case .search: 0.82
        case .home, .storage: 0.86
        case .star, .starEmpty: 0.92
        case .cancel, .checkbox, .setting, .information, .grid, .list, .error, .success,
             .shopping, .place, .schedule, .idea, .book, .event, .record, .noImage, .check:
            0.86
        }
    }

    var defaultWeight: Font.Weight {
        switch self {
        case .plus, .back, .forward, .dropdown, .check: .semibold
        case .cancel, .cancelCircle, .star, .starEmpty, .home, .storage, .more, .search,
             .checkbox, .setting, .information, .grid, .list, .error, .success,
             .shopping, .place, .schedule, .idea, .book, .event, .record, .noImage:
            .regular
        }
    }

    var assetName: String? {
        switch self {
        case .home: "RecapTabHomeIcon"
        case .storage: "RecapTabArchiveIcon"
        default: nil
        }
    }
}

struct RecapIconView: View {
    let icon: RecapIcon
    var size: CGFloat?
    var color: Color = Color.recapGray900
    var weight: Font.Weight?

    private var resolvedSize: CGFloat { size ?? icon.defaultSize }
    private var resolvedWeight: Font.Weight { weight ?? icon.defaultWeight }

    var body: some View {
        Group {
            if let assetName = icon.assetName {
                Image(assetName)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .padding(resolvedSize * 0.07)
            } else {
                Image(systemName: icon.systemName)
                    .font(.system(size: resolvedSize * icon.symbolScale, weight: resolvedWeight))
            }
        }
        .foregroundStyle(color)
        .frame(width: resolvedSize, height: resolvedSize)
        .accessibilityLabel(icon.figmaName)
    }
}

#Preview("Recap icons") {
    ScrollView(.horizontal, showsIndicators: true) {
        LazyHStack(spacing: RecapTheme.Spacing.medium) {
            ForEach(RecapIcon.allCases) { icon in
                VStack(spacing: 8) {
                    RecapIconView(icon: icon)
                    Text(icon.rawValue)
                        .font(RecapFont.pretendard(size: 10, weight: .medium))
                        .foregroundStyle(Color.recapGray500)
                }
            }
        }
        .padding()
    }
    .background(Color.recapBackground)
}
