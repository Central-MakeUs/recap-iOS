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
    static let rowHeight: CGFloat = 44
    /// 행 제목(15pt Medium) 한 줄 높이. Figma 기준 21pt.
    static let rowTextHeight: CGFloat = 21
    /// Figma에서 섹션 제목 아래부터 첫 행 "텍스트"까지의 간격.
    static let sectionTitleToRowText: CGFloat = 25
    /// 행 텍스트는 44pt 박스 안에서 수직 중앙에 놓이므로 그만큼 빼야 Figma와 같아진다.
    static let sectionTitleToRows: CGFloat =
        sectionTitleToRowText - (rowHeight - rowTextHeight) / 2
    static let sectionBottomPadding: CGFloat = 9
    static let dividerHeight: CGFloat = 8
}
