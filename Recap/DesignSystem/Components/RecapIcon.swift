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
    case career
    case noImage
    case check
    case aiEdit

    var id: String { rawValue }

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
        case .career: "icon/career"
        case .noImage: "icon/noimage"
        case .check: "icon/check"
        case .aiEdit: "si:ai-edit-fill"
        }
    }

    var defaultSize: CGFloat {
        switch self {
        case .cancelCircle, .dropdown, .checkbox, .shopping, .place, .schedule, .idea, .book, .event, .record, .career, .aiEdit:
            16
        case .plus: 30
        case .star, .starEmpty, .cancel, .back, .forward, .search, .home, .storage, .more,
             .setting, .information, .grid, .list, .error, .success, .noImage, .check:
            24
        }
    }

    func assetName(for size: CGFloat) -> String {
        switch self {
        case .star: "RecapIconStar"
        case .starEmpty: "RecapIconStarEmpty"
        case .cancel: "RecapIconCancel"
        case .cancelCircle:
            size <= 16 ? "RecapIconCancelCircleS" : "RecapIconCancelCircleM"
        case .back: "RecapIconBack"
        case .forward:
            size <= 16 ? "RecapIconForwardS" : "RecapIconForwardM"
        case .search: "RecapIconSearch"
        case .home: "RecapIconHome"
        case .storage: "RecapIconStorage"
        case .plus:
            size <= 24 ? "RecapIconPlusM" : "RecapIconPlusL"
        case .more: "RecapIconMore"
        case .dropdown: "RecapIconDropdown"
        case .checkbox: "RecapIconCheckbox"
        case .setting: "RecapIconSetting"
        case .information: "RecapIconInformation"
        case .grid: "RecapIconGrid"
        case .list: "RecapIconList"
        case .error:
            size <= 16 ? "RecapIconErrorS" : "RecapIconErrorM"
        case .success: "RecapIconSuccess"
        case .shopping: "RecapIconShopping"
        case .place: "RecapIconPlace"
        case .schedule: "RecapIconSchedule"
        case .idea: "RecapIconIdea"
        case .book: "RecapIconBook"
        case .event: "RecapIconEvent"
        case .record: "RecapIconRecord"
        case .career: "RecapIconCareer"
        case .noImage: "RecapIconNoImage"
        case .check: "RecapIconCheck"
        case .aiEdit: "RecapIconAiEdit"
        }
    }

    static func categoryIcon(for kind: CardCategory) -> RecapIcon {
        switch kind {
        case .shopping:
            .shopping
        case .place:
            .place
        case .schedule:
            .schedule
        case .knowledge:
            .idea
        case .content:
            .book
        case .benefits:
            .event
        case .capture:
            .record
        case .career:
            .career
        case .other:
            .storage
        }
    }
}

struct RecapIconView: View {
    let icon: RecapIcon
    var size: CGFloat?
    var color: Color = Color.recapGray900

    private var resolvedSize: CGFloat { size ?? icon.defaultSize }

    var body: some View {
        Image(icon.assetName(for: resolvedSize))
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .foregroundStyle(color)
            .frame(width: resolvedSize, height: resolvedSize)
            .accessibilityLabel(icon.figmaName)
    }
}

#if DEBUG
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
#endif
