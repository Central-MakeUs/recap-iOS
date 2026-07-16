import SwiftUI

struct CardEditTypeSelectionSheet: View {
    @Environment(\.dismiss) private var dismiss

    @Binding private var selection: CollectionKind
    @State private var pendingSelection: CollectionKind

    private let columns = Array(
        repeating: GridItem(.flexible(), spacing: 8),
        count: 3
    )

    init(selection: Binding<CollectionKind>) {
        _selection = selection
        _pendingSelection = State(initialValue: selection.wrappedValue)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("유형 변경")
                .font(RecapFont.pretendard(size: 16, weight: .semibold))
                .tracking(-0.32)
                .foregroundStyle(Color.recapGray900)
                .padding(.leading, 22)

            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(CollectionKind.allCases) { kind in
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
            .padding(.horizontal, 16)
            .padding(.top, 23)

            Spacer(minLength: 0)

            RecapButton(title: "선택 완료", action: confirmSelection)
            .padding(.horizontal, 16)
            .padding(.bottom, 20)
        }
        .padding(.top, 24)
        .frame(height: 384)
        .background(Color.white)
    }

    private func confirmSelection() {
        selection = pendingSelection
        dismiss()
    }
}

#Preview("정보카드 유형 선택") {
    @Previewable @State var selection = CollectionKind.schedule

    CardEditTypeSelectionSheet(selection: $selection)
}
