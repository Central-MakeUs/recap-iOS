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
    /// 섹션 제목 아래부터 첫 행 텍스트까지의 간격.
    static let sectionTitleToRows: CGFloat = 25
    /// 같은 섹션 안의 텍스트 행 사이 간격.
    static let rowSpacing: CGFloat = 23
    static let sectionBottomPadding: CGFloat = 32
    static let dividerHeight: CGFloat = 8
}
