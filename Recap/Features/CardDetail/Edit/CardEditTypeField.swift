import SwiftUI

struct CardEditTypeField: View {
    @Binding var collection: CollectionKind
    @State private var isTypeSelectionPresented = false

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            CardEditFieldLabel(title: "유형")

            Button {
                isTypeSelectionPresented = true
            } label: {
                HStack {
                    Text(RecapPresentation.collectionDisplay(for: collection).title)
                        .font(RecapFont.pretendard(size: 14, weight: .regular))
                        .tracking(-0.28)
                        .foregroundStyle(RecapTheme.ColorToken.textPrimary)

                    Spacer()

                    Text("변경")
                        .font(RecapFont.pretendard(size: 13, weight: .medium))
                        .tracking(-0.26)
                        .foregroundStyle(Color(red: 56 / 255, green: 69 / 255, blue: 199 / 255))
                }
                .padding(.horizontal, 12)
                .frame(height: 46)
                .cardEditFieldStyle()
            }
            .buttonStyle(.plain)
        }
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
