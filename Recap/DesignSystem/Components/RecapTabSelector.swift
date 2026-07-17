import SwiftUI

struct RecapTabSelector: View {
    let selection: MainTab
    let onSelect: (MainTab) -> Void

    @Namespace private var selectionBackground

    var body: some View {
        HStack(spacing: 3) {
            RecapTabButton(
                tab: .home,
                iconName: "RecapTabHomeIcon",
                label: "홈",
                isSelected: selection == .home,
                selectionBackground: selectionBackground,
                action: { onSelect(.home) }
            )
            RecapTabButton(
                tab: .archive,
                iconName: "RecapTabArchiveIcon",
                label: "보관함",
                isSelected: selection == .archive,
                selectionBackground: selectionBackground,
                action: { onSelect(.archive) }
            )
        }
        .padding(4)
        .frame(
            width: RecapMainTabBarMetrics.selectorSize.width,
            height: RecapMainTabBarMetrics.selectorSize.height
        )
        .background(Color.white)
        .clipShape(Capsule())
        .animation(.snappy(duration: 0.28, extraBounce: 0), value: selection)
    }
}

private struct RecapTabButton: View {
    let tab: MainTab
    let iconName: String
    let label: String
    let isSelected: Bool
    let selectionBackground: Namespace.ID
    let action: () -> Void

    var body: some View {
        Image(iconName)
            .renderingMode(.template)
            .resizable()
            .frame(width: 24, height: 24)
            .foregroundStyle(isSelected ? Color.recapBrandBlue : Color.recapGray200)
        .frame(
            width: RecapMainTabBarMetrics.tabItemSize.width,
            height: RecapMainTabBarMetrics.tabItemSize.height
        )
        .background(
            selectionCapsule
        )
        .contentShape(Capsule())
        .clipShape(Capsule())
        .onTapGesture {
            withAnimation(.snappy(duration: 0.28, extraBounce: 0)) {
                action()
            }
        }
        .accessibilityElement()
        .accessibilityLabel(label)
        .accessibilityIdentifier("mainTab.\(tab.rawValue)")
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
        .accessibilityAction {
            action()
        }
    }

    @ViewBuilder
    private var selectionCapsule: some View {
        if isSelected {
            Capsule()
                .fill(Color.recapBlue50)
                .matchedGeometryEffect(
                    id: "selectedMainTab",
                    in: selectionBackground
                )
        }
    }
}

#Preview("홈 선택") {
    @Previewable @State var selection = MainTab.home
    RecapTabSelector(
        selection: selection,
        onSelect: { selection = $0 }
    )
        .padding()
        .background(Color.recapBackground)
}

#Preview("보관함 선택") {
    @Previewable @State var selection = MainTab.archive
    RecapTabSelector(
        selection: selection,
        onSelect: { selection = $0 }
    )
        .padding()
        .background(Color.recapBackground)
}
