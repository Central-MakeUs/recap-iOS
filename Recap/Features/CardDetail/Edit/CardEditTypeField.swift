import SwiftUI

struct CardEditTypeField: View {
    @Binding var category: CardCategory
    @State private var isTypeSelectionPresented = false

    var body: some View {
        RecapActionInput(
            label: "유형",
            value: RecapPresentation.categoryDisplay(for: category).title,
            actionTitle: "변경",
            action: { isTypeSelectionPresented = true }
        )
        .recapBottomSheet(
            isPresented: $isTypeSelectionPresented,
            height: 384,
            cornerRadius: 32
        ) {
            CardEditTypeSelectionSheet(
                selection: $category,
                onSelectionConfirmed: closeTypeSelection
            )
        }
    }

    private func closeTypeSelection() {
        isTypeSelectionPresented = false
    }
}

#if DEBUG
#Preview("정보카드 유형 입력") {
    @Previewable @State var category = CardCategory.schedule
    CardEditTypeField(category: $category)
        .padding()
}
#endif
