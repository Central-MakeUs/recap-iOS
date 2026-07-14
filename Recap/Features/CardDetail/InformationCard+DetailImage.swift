import Foundation

extension InformationCard {
    var detailImageAssetName: String? {
        originalImageAssetName ?? thumbnailAssetName
    }
}
