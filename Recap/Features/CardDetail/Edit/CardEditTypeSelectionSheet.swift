import SwiftUI

struct CardEditTypeSelectionSheet: View {
    @Binding private var selection: CardCategory
    @State private var pendingSelection: CardCategory

    private let onSelectionConfirmed: () -> Void

    init(
        selection: Binding<CardCategory>,
        onSelectionConfirmed: @escaping () -> Void
    ) {
        _selection = selection
        _pendingSelection = State(initialValue: selection.wrappedValue)
        self.onSelectionConfirmed = onSelectionConfirmed
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("유형 변경")
                .font(RecapFont.pretendard(size: 16, weight: .semibold))
                .tracking(-0.32)
                .foregroundStyle(Color.recapGray900)
                .padding(.leading, 22)

            Grid(horizontalSpacing: 8, verticalSpacing: 20) {
                ForEach(categoryRows.indices, id: \.self) { rowIndex in
                    GridRow {
                        ForEach(categoryRows[rowIndex]) { kind in
                            categoryButton(for: kind)
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 23)

            Spacer(minLength: 0)

            RecapButton(title: "선택 완료", action: confirmSelection)
            .padding(.horizontal, 16)
            .padding(.bottom, 20)
        }
        .padding(.top, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private func confirmSelection() {
        selection = pendingSelection
        onSelectionConfirmed()
    }

    private var categoryRows: [[CardCategory]] {
        let categories = CardCategory.allCases

        return stride(from: 0, to: categories.count, by: 3).map { startIndex in
            Array(categories[startIndex..<min(startIndex + 3, categories.count)])
        }
    }

    private func categoryButton(for kind: CardCategory) -> some View {
        Button {
            pendingSelection = kind
        } label: {
            RecapChip(
                configuration: .category(
                    kind,
                    size: .large,
                    isSelected: pendingSelection == kind
                )
            )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(pendingSelection == kind ? .isSelected : [])
    }
}

#if DEBUG
#Preview("정보카드 유형 선택") {
    @Previewable @State var selection = CardCategory.schedule

    CardEditTypeSelectionSheet(
        selection: $selection,
        onSelectionConfirmed: PreviewActions.noop
    )
}
#endif
