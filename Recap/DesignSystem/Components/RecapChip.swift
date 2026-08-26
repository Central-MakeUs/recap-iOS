import SwiftUI

struct RecapChip: View {
    enum Configuration {
        case category(CardCategory, size: CategorySize, isSelected: Bool = true)
        case recentSearch(String)
    }

    enum CategorySize {
        case small
        case medium
        case large
    }

    let configuration: Configuration
    var onSelect: () -> Void = {}
    var onRemove: () -> Void = {}

    var body: some View {
        switch configuration {
        case let .category(category, size, isSelected):
            categoryChip(for: category, size: size, isSelected: isSelected)
        case let .recentSearch(keyword):
            recentSearchChip(keyword: keyword)
        }
    }

    @ViewBuilder
    private func categoryChip(
        for category: CardCategory,
        size: CategorySize,
        isSelected: Bool
    ) -> some View {
        switch size {
        case .small:
            categoryTitle(for: category, color: category.chipPalette.text)
        case .medium:
            HStack(spacing: 8) {
                RecapCategoryIcon.chip(category)
                categoryTitle(for: category, color: Color.recapGray900)
            }
        case .large:
            let palette = isSelected ? category.chipPalette : .unselected

            Text(category.displayTitle)
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

    private func categoryTitle(for category: CardCategory, color: Color) -> some View {
        Text(category.displayTitle)
            .font(RecapFont.pretendard(size: 10, weight: .semibold))
            .tracking(-0.20)
            .foregroundStyle(color)
            .lineLimit(1)
    }


    private func recentSearchChip(keyword: String) -> some View {
        HStack(spacing: 0) {
            Button(action: onSelect) {
                Text(keyword)
                    .font(RecapFont.pretendard(size: 14, weight: .regular))
                    .tracking(-0.28)
                    .frame(height: 30)
            }
            .buttonStyle(.plain)
            .padding(.trailing, 10)

            Button(action: onRemove) {
                RecapIconView(
                    icon: .cancelCircle,
                    size: 16,
                    color: Color.recapGray300
                )
                .frame(width: 24, height: 30)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(keyword) 최근 검색어 삭제")
        }
        .foregroundStyle(Color.recapGray500)
        .padding(.leading, 12)
        .padding(.trailing, 6)
        .frame(height: 30)
        .background(Color.recapGray50)
        .clipShape(Capsule())
    }
}

#if DEBUG
#Preview("Chips - 카테고리 S") {
    VStack(alignment: .leading, spacing: 12) {
        ForEach(CardCategory.allCases) { category in
            RecapChip(configuration: .category(category, size: .small))
        }
    }
    .padding()
}

#Preview("Chips - 카테고리 M") {
    VStack(alignment: .leading, spacing: 12) {
        ForEach(CardCategory.allCases) { category in
            RecapChip(configuration: .category(category, size: .medium))
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
#endif
