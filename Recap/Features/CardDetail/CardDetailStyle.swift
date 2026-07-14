import SwiftUI

enum CardDetailImageState: Hashable {
    case loaded
    case failedFullWidth
    case failedCard
}

enum CardDetailOverlayState: Hashable {
    case none
    case actions
    case deleteConfirmation
    case favoriteToast
    case deleteFailure
}

enum CardEditOverlayState: Hashable {
    case none
    case discardConfirmation
    case saveFailure
}

enum CardDetailStyle {
    static let horizontalPadding: CGFloat = 16
    static let heroHeight: CGFloat = 285
    static let heroGradientHeight: CGFloat = 237
    static let imageCardHeight: CGFloat = 184
    static let cornerRadius: CGFloat = 10

    static let destructive = Color(red: 1, green: 100 / 255, blue: 100 / 255)
    static let destructiveText = Color(red: 251 / 255, green: 61 / 255, blue: 61 / 255)
    static let success = Color(red: 31 / 255, green: 205 / 255, blue: 112 / 255)
    static let dim = Color.black.opacity(0.30)
    static let toastBackground = Color.black.opacity(0.50)
    static let inputBorder = Color(red: 206 / 255, green: 210 / 255, blue: 222 / 255)
    static let imageFailureFill = Color(red: 246 / 255, green: 246 / 255, blue: 246 / 255)
}
