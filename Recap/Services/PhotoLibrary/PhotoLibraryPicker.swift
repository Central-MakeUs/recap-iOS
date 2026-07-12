import Foundation
import PhotosUI
import SwiftUI

struct PhotoLibraryPicker<Label: View>: View {
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var isLoading = false

    let maxSelectionCount: Int
    let loader: any PhotoLibraryLoading
    let onLoad: ([Data], Int) -> Void
    @ViewBuilder let label: (Bool) -> Label

    init(
        maxSelectionCount: Int,
        loader: any PhotoLibraryLoading = LivePhotoLibraryLoader(),
        onLoad: @escaping ([Data], Int) -> Void,
        @ViewBuilder label: @escaping (Bool) -> Label
    ) {
        self.maxSelectionCount = maxSelectionCount
        self.loader = loader
        self.onLoad = onLoad
        self.label = label
    }

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
            let result = await loader.load(items)

            await MainActor.run {
                isLoading = false
                selectedItems = []
                onLoad(result.imageData, result.failedCount)
            }
        }
    }
}
