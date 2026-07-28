import CoreGraphics

enum RecapMainTabBarMetrics {
    static let height: CGFloat = 111
    static let horizontalPadding: CGFloat = 22
    static let topPadding: CGFloat = 28.5
    static let selectorSize = CGSize(width: 155, height: 54)
    static let tabItemSize = CGSize(width: 72, height: 46)
    static let uploadButtonSize = CGSize(width: 107, height: 54)
    static let shadowOpacity: CGFloat = 0.14
    static let shadowRadius: CGFloat = 10
    static let shadowY: CGFloat = 4

    static func contentHeight(bottomSafeAreaInset: CGFloat) -> CGFloat {
        max(0, height - bottomSafeAreaInset)
    }

    static func barFrame(in viewport: CGSize) -> CGRect {
        CGRect(
            x: 0,
            y: viewport.height - height,
            width: viewport.width,
            height: height
        )
    }

    static func selectorFrame(in viewport: CGSize) -> CGRect {
        CGRect(
            x: horizontalPadding,
            y: viewport.height - height + topPadding,
            width: selectorSize.width,
            height: selectorSize.height
        )
    }

    static func uploadButtonFrame(in viewport: CGSize) -> CGRect {
        CGRect(
            x: viewport.width - horizontalPadding - uploadButtonSize.width,
            y: viewport.height - height + topPadding,
            width: uploadButtonSize.width,
            height: uploadButtonSize.height
        )
    }
}
