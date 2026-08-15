import SwiftUI

struct RecapCategoryIcon: View {
    enum Size {
        case medium
        case large

        var container: CGFloat {
            switch self {
            case .medium: 61
            case .large: 71
            }
        }

        var symbol: CGFloat { 30 }
    }

    let kind: CardCategory
    var size: Size = .medium

    var body: some View {
        let display = RecapPresentation.collectionDisplay(for: kind)

        Group {
            if kind == .other {
                RoundedRectangle(cornerRadius: 2.5, style: .continuous)
                    .fill(Color.recapGray200)
                    .frame(width: otherSymbolWidth, height: 4)
            } else {
                RecapIconView(
                    icon: .categoryIcon(for: kind),
                    size: size.symbol,
                    color: display.dotColor
                )
            }
        }
            .frame(width: size.container, height: size.container)
            .background(Color.recapCategorySurface)
            .clipShape(RoundedRectangle(cornerRadius: 27, style: .continuous))
    }

    private var otherSymbolWidth: CGFloat {
        switch size {
        case .medium: 22
        case .large: 24
        }
    }
}

#if DEBUG
#Preview("카테고리 아이콘") {
    HStack {
        RecapCategoryIcon(kind: .shopping)
        RecapCategoryIcon(kind: .schedule, size: .large)
    }
    .padding()
}
#endif
