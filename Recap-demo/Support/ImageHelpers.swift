import Foundation
import UIKit

extension UIImage {
    func jpegDataForThumbnail(maxDimension: CGFloat = 360) -> Data? {
        let scale = min(maxDimension / max(size.width, size.height), 1)
        let targetSize = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        let rendered = renderer.image { _ in draw(in: CGRect(origin: .zero, size: targetSize)) }
        return rendered.jpegData(compressionQuality: 0.72)
    }
}

extension TimeInterval {
    var secondsText: String { String(format: "%.2fs", self) }
}
