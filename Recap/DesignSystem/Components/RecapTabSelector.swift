import SwiftUI

struct RecapTabSelector: View {
    let selection: MainTab
    let onSelect: (MainTab) -> Void

    var body: some View {
        HStack(spacing: 3) {
            RecapTabButton(
                tab: .home,
                iconName: "RecapTabHomeIcon",
                label: "홈",
                isSelected: selection == .home,
                action: { onSelect(.home) }
            )
            RecapTabButton(
                tab: .archive,
                iconName: "RecapTabArchiveIcon",
                label: "보관함",
                isSelected: selection == .archive,
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
    }
}

private struct RecapTabButton: View {
    let tab: MainTab
    let iconName: String
    let label: String
    let isSelected: Bool
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
            isSelected ? Color.recapBlue50 : Color.clear
        )
        .contentShape(Capsule())
        .clipShape(Capsule())
        .onTapGesture(perform: action)
        .accessibilityElement()
        .accessibilityLabel(label)
        .accessibilityIdentifier("mainTab.\(tab.rawValue)")
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
        .accessibilityAction {
            action()
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
