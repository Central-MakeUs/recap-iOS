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

    let kind: CollectionKind
    var size: Size = .medium

    var body: some View {
        let display = RecapPresentation.collectionDisplay(for: kind)

        Image(systemName: display.symbolName)
            .font(.system(size: size.symbol, weight: .bold))
            .foregroundStyle(display.dotColor)
            .frame(width: size.container, height: size.container)
            .background(Color.recapCategorySurface)
            .clipShape(RoundedRectangle(cornerRadius: 27, style: .continuous))
    }
}

#Preview("카테고리 아이콘") {
    HStack {
        RecapCategoryIcon(kind: .shopping)
        RecapCategoryIcon(kind: .schedule, size: .large)
    }
    .padding()
}
