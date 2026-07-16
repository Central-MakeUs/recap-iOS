import SwiftUI

struct RecapChip: View {
    enum Configuration {
        case category(CollectionKind, size: CategorySize, isSelected: Bool = true)
        case recentSearch(String)
    }

    enum CategorySize {
        case small
        case medium
        case large
    }

    let configuration: Configuration

    var body: some View {
        switch configuration {
        case let .category(kind, size, isSelected):
            categoryChip(kind: kind, size: size, isSelected: isSelected)
        case let .recentSearch(keyword):
            recentSearchChip(keyword: keyword)
        }
    }

    @ViewBuilder
    private func categoryChip(
        kind: CollectionKind,
        size: CategorySize,
        isSelected: Bool
    ) -> some View {
        switch size {
        case .small:
            categoryTitle(kind: kind, color: CategoryPalette.selected(for: kind).text)
        case .medium:
            HStack(spacing: 8) {
                categoryIcon(kind: kind)
                categoryTitle(kind: kind, color: RecapTheme.ColorToken.textPrimary)
            }
        case .large:
            let palette = isSelected ? CategoryPalette.selected(for: kind) : .unselected

            Text(RecapPresentation.collectionDisplay(for: kind).title)
                .font(RecapFont.pretendard(size: 14, weight: .semibold))
                .tracking(-0.28)
                .foregroundStyle(palette.text)
                .frame(width: 109, height: 48)
                .background(palette.background)
                .clipShape(Capsule())
                .overlay {
                    Capsule()
                        .stroke(palette.border, lineWidth: 1)
                }
        }
    }

    private func categoryTitle(kind: CollectionKind, color: Color) -> some View {
        Text(RecapPresentation.collectionDisplay(for: kind).title)
            .font(RecapFont.pretendard(size: 10, weight: .semibold))
            .tracking(-0.20)
            .foregroundStyle(color)
            .lineLimit(1)
    }

    private func categoryIcon(kind: CollectionKind) -> some View {
        let display = RecapPresentation.collectionDisplay(for: kind)

        return Image(systemName: display.symbolName)
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(display.textColor)
            .frame(width: 24, height: 24)
    }

    private func recentSearchChip(keyword: String) -> some View {
        HStack(spacing: 10) {
            Text(keyword)
                .font(RecapFont.pretendard(size: 14, weight: .regular))
                .tracking(-0.28)

            Image(systemName: "xmark")
                .font(.system(size: 10, weight: .semibold))
                .frame(width: 16, height: 16)
        }
        .foregroundStyle(RecapTheme.ColorToken.textSecondary)
        .padding(.horizontal, 12)
        .frame(height: 30)
        .background(RecapTheme.ColorToken.gray50)
        .clipShape(Capsule())
    }
}

private struct CategoryPalette {
    let background: Color
    let border: Color
    let text: Color

    static let unselected = CategoryPalette(
        background: .white,
        border: RecapTheme.ColorToken.border,
        text: RecapTheme.ColorToken.textTertiary
    )

    static func selected(for kind: CollectionKind) -> CategoryPalette {
        switch kind {
        case .shopping:
            CategoryPalette(
                background: .categoryBlue300,
                border: .categoryBlue500,
                text: .categoryBlue700
            )
        case .place:
            CategoryPalette(
                background: .categoryRed300,
                border: .categoryRed500,
                text: .categoryRed700
            )
        case .schedule:
            CategoryPalette(
                background: .categoryGreen300,
                border: .categoryGreen500,
                text: .categoryGreen700
            )
        case .knowledge:
            CategoryPalette(
                background: .categoryYellow300,
                border: .categoryYellow500,
                text: .categoryYellow700
            )
        case .content:
            CategoryPalette(
                background: .categoryGray300,
                border: .categoryGray500,
                text: .categoryGray700
            )
        case .benefits:
            CategoryPalette(
                background: .categoryMint300,
                border: .categoryMint500,
                text: .categoryMint700
            )
        case .capture:
            CategoryPalette(
                background: .categoryPurple300,
                border: .categoryPurple500,
                text: .categoryPurple700
            )
        case .career:
            CategoryPalette(
                background: .categoryOrange300,
                border: .categoryOrange500,
                text: .categoryOrange700
            )
        case .other:
            CategoryPalette(
                background: .categoryGray300,
                border: .categoryGray500,
                text: .categoryGray700
            )
        }
    }
}

#Preview("Chips - 카테고리 S") {
    VStack(alignment: .leading, spacing: 12) {
        ForEach(CollectionKind.allCases) { kind in
            RecapChip(configuration: .category(kind, size: .small))
        }
    }
    .padding()
}

#Preview("Chips - 카테고리 M") {
    VStack(alignment: .leading, spacing: 12) {
        ForEach(CollectionKind.allCases) { kind in
            RecapChip(configuration: .category(kind, size: .medium))
        }
    }
    .padding()
}

#Preview("Chips - 카테고리 L") {
    VStack(spacing: 12) {
        RecapChip(configuration: .category(.schedule, size: .large))
        RecapChip(configuration: .category(.schedule, size: .large, isSelected: false))
    }
    .frame(width: 109)
    .padding()
}

#Preview("Chips - 최근 검색") {
    RecapChip(configuration: .recentSearch("검색어 01234"))
        .padding()
}
