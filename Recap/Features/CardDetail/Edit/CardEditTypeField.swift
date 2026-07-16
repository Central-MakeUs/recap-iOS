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
        .sheet(isPresented: $isTypeSelectionPresented) {
            CardEditTypeSelectionSheet(selection: $collection)
                .presentationDetents([.height(384)])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(32)
                .presentationBackground(Color.white)
        }
    }
}

#Preview("정보카드 유형 입력") {
    @Previewable @State var collection = CollectionKind.schedule
    CardEditTypeField(collection: $collection)
        .padding()
}
