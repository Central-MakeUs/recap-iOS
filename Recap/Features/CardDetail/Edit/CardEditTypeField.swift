import SwiftUI

struct CardEditTypeField: View {
    @Binding var collection: CollectionKind
    @State private var isTypeSelectionPresented = false

    var body: some View {
        RecapActionInput(
            label: "유형",
            value: RecapPresentation.collectionDisplay(for: collection).title,
            actionTitle: "변경",
            action: { isTypeSelectionPresented = true }
        )
        .recapBottomSheet(
            isPresented: $isTypeSelectionPresented,
            height: 384,
            cornerRadius: 32
        ) {
            CardEditTypeSelectionSheet(
                selection: $collection,
                onSelectionConfirmed: closeTypeSelection
            )
        }
    }

    private func closeTypeSelection() {
        isTypeSelectionPresented = false
    }
}

#Preview("정보카드 유형 입력") {
    @Previewable @State var collection = CollectionKind.schedule
    CardEditTypeField(collection: $collection)
        .padding()
}
