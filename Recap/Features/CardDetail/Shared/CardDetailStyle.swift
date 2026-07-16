import SwiftUI

enum CardDetailImageState: Hashable {
    case loaded
    case failedFullWidth
    case failedCard

    var imageTopInset: CGFloat {
        switch self {
        case .loaded, .failedFullWidth:
            0
        case .failedCard:
            CardDetailStyle.failedImageCardTopInset
        }
    }

    var metadataSpacing: CGFloat {
        switch self {
        case .loaded, .failedFullWidth:
            CardDetailStyle.fullWidthImageMetadataSpacing
        case .failedCard:
            CardDetailStyle.imageCardMetadataSpacing
        }
    }
}

enum CardDetailStyle {
    static let horizontalPadding: CGFloat = 16
    static let heroHeight: CGFloat = 285
    static let heroGradientHeight: CGFloat = 237
    static let imageCardHeight: CGFloat = 184
    static let cornerRadius: CGFloat = 10
    static let failedImageCardTopInset: CGFloat = 145
    static let fullWidthImageMetadataSpacing: CGFloat = 22
    static let imageCardMetadataSpacing: CGFloat = 20
}
