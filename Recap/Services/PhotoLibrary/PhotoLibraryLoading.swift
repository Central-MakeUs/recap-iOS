import Foundation
import PhotosUI
import SwiftUI
import UIKit

struct PhotoLibraryLoadResult {
    let imageData: [Data]
    let failedCount: Int
}

protocol PhotoLibraryLoading {
    func load(_ items: [PhotosPickerItem]) async -> PhotoLibraryLoadResult
}

struct LivePhotoLibraryLoader: PhotoLibraryLoading {
    func load(_ items: [PhotosPickerItem]) async -> PhotoLibraryLoadResult {
        var imageData: [Data] = []
        var failedCount = 0

        for item in items {
            do {
                if
                    let sourceData = try await item.loadTransferable(type: Data.self),
                    let image = UIImage(data: sourceData),
                    let jpegData = image.jpegData(compressionQuality: 0.9)
                {
                    imageData.append(jpegData)
                } else {
                    failedCount += 1
                }
            } catch {
                failedCount += 1
            }
        }

        return PhotoLibraryLoadResult(
            imageData: imageData,
            failedCount: failedCount
        )
    }
}
