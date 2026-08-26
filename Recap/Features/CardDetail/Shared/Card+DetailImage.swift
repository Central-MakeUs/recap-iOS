import Foundation

extension Card {
    var detailImageAssetName: String? {
        originalImageAssetName ?? thumbnailAssetName
    }
}
