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
        .background(Color(red: 243 / 255, green: 245 / 255, blue: 249 / 255))
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
                background: Color(red: 215 / 255, green: 232 / 255, blue: 1),
                border: Color(red: 169 / 255, green: 205 / 255, blue: 1),
                text: Color(red: 49 / 255, green: 84 / 255, blue: 132 / 255)
            )
        case .place:
            CategoryPalette(
                background: Color(red: 1, green: 224 / 255, blue: 224 / 255),
                border: Color(red: 1, green: 182 / 255, blue: 182 / 255),
                text: Color(red: 209 / 255, green: 75 / 255, blue: 75 / 255)
            )
        case .schedule:
            CategoryPalette(
                background: Color(red: 231 / 255, green: 251 / 255, blue: 220 / 255),
                border: Color(red: 156 / 255, green: 220 / 255, blue: 122 / 255),
                text: Color(red: 53 / 255, green: 111 / 255, blue: 20 / 255)
            )
        case .knowledge:
            CategoryPalette(
                background: Color(red: 254 / 255, green: 240 / 255, blue: 193 / 255),
                border: Color(red: 1, green: 224 / 255, blue: 120 / 255),
                text: Color(red: 129 / 255, green: 105 / 255, blue: 26 / 255)
            )
        case .content:
            CategoryPalette(
                background: Color(red: 234 / 255, green: 234 / 255, blue: 234 / 255),
                border: Color(red: 175 / 255, green: 175 / 255, blue: 175 / 255),
                text: Color(red: 113 / 255, green: 113 / 255, blue: 113 / 255)
            )
        case .benefits:
            CategoryPalette(
                background: Color(red: 215 / 255, green: 249 / 255, blue: 1),
                border: Color(red: 148 / 255, green: 231 / 255, blue: 225 / 255),
                text: Color(red: 1 / 255, green: 146 / 255, blue: 170 / 255)
            )
        case .capture:
            CategoryPalette(
                background: Color(red: 226 / 255, green: 219 / 255, blue: 1),
                border: Color(red: 150 / 255, green: 132 / 255, blue: 230 / 255),
                text: Color(red: 106 / 255, green: 81 / 255, blue: 211 / 255)
            )
        case .career:
            CategoryPalette(
                background: Color(red: 1, green: 214 / 255, blue: 181 / 255),
                border: Color(red: 1, green: 194 / 255, blue: 144 / 255),
                text: Color(red: 209 / 255, green: 99 / 255, blue: 8 / 255)
            )
        case .other:
            CategoryPalette(
                background: Color(red: 234 / 255, green: 234 / 255, blue: 234 / 255),
                border: Color(red: 175 / 255, green: 175 / 255, blue: 175 / 255),
                text: Color(red: 113 / 255, green: 113 / 255, blue: 113 / 255)
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
