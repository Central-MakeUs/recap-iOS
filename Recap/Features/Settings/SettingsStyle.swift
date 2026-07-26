import SwiftUI

enum SettingsTypography {
    static let navigationTitle = RecapFont.pretendard(size: 16, weight: .semibold)
    static let sectionTitle = RecapFont.pretendard(size: 14, weight: .regular)
    static let rowTitle = RecapFont.pretendard(size: 15, weight: .medium)
    static let rowStatus = RecapFont.pretendard(size: 14, weight: .semibold)
    static let body = RecapFont.pretendard(size: 14, weight: .regular)
    static let noticeTitle = RecapFont.pretendard(size: 14, weight: .semibold)
}

enum SettingsLayout {
    static let horizontalPadding: CGFloat = 28
    static let navigationHorizontalPadding: CGFloat = 16
    static let navigationTopPadding: CGFloat = 9
    static let navigationHeight: CGFloat = 44
    static let sectionTopPadding: CGFloat = 32
    static let firstSectionTopPadding: CGFloat = 11
    static let sectionTitleToRows: CGFloat = 25
    static let rowHeight: CGFloat = 44
    static let sectionBottomPadding: CGFloat = 9
    static let dividerHeight: CGFloat = 8
}
