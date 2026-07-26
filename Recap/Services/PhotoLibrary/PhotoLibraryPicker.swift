import PhotosUI
import SwiftUI

struct ScreenshotPhotoPickerPresenter: View {
    @Binding var isPresented: Bool

    let maxSelectionCount: Int
    let loader: any PhotoLibraryLoading
    let onLoad: ([Data], Int) -> Void
    let onCancel: () -> Void

    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var isLoading = false
    @State private var didSubmitSelection = false

    init(
        isPresented: Binding<Bool>,
        maxSelectionCount: Int,
        loader: any PhotoLibraryLoading = LivePhotoLibraryLoader(),
        onLoad: @escaping ([Data], Int) -> Void,
        onCancel: @escaping () -> Void
    ) {
        _isPresented = isPresented
        self.maxSelectionCount = maxSelectionCount
        self.loader = loader
        self.onLoad = onLoad
        self.onCancel = onCancel
    }

    var body: some View {
        Color.clear
            .photosPicker(
                isPresented: $isPresented,
                selection: $selectedItems,
                maxSelectionCount: maxSelectionCount,
                matching: .screenshots
            )
            .onChange(of: selectedItems) { _, items in
                guard !items.isEmpty else { return }
                didSubmitSelection = true
                load(items)
            }
            .onChange(of: isPresented) { wasPresented, isPresented in
                if !wasPresented, isPresented {
                    didSubmitSelection = false
                    selectedItems = []
                    return
                }
                guard wasPresented, !isPresented else { return }
                handlePickerDismissal()
            }
            .allowsHitTesting(false)
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

    private func handlePickerDismissal() {
        Task { @MainActor in
            await Task.yield()
            guard !didSubmitSelection, !isLoading, selectedItems.isEmpty else {
                return
            }
            onCancel()
        }
    }
}
