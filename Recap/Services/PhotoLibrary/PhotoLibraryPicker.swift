import Foundation
import PhotosUI
import SwiftUI

struct PhotoLibraryPicker<Label: View>: View {
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var isLoading = false

    let maxSelectionCount: Int
    let onLoad: ([Data], Int) -> Void
    @ViewBuilder let label: (Bool) -> Label

    var body: some View {
        PhotosPicker(
            selection: $selectedItems,
            maxSelectionCount: maxSelectionCount,
            matching: .images
        ) {
            label(isLoading)
        }
        .disabled(isLoading)
        .onChange(of: selectedItems) { _, items in
            guard !items.isEmpty else { return }
            load(items)
        }
    }

    private func load(_ items: [PhotosPickerItem]) {
        isLoading = true
        Task {
            var imageData: [Data] = []
            var failedCount = 0

            for item in items {
                do {
                    if let data = try await item.loadTransferable(type: Data.self) {
                        imageData.append(data)
                    } else {
                        failedCount += 1
                    }
                } catch {
                    failedCount += 1
                }
            }

            await MainActor.run {
                isLoading = false
                selectedItems = []
                onLoad(imageData, failedCount)
            }
        }
    }
}
