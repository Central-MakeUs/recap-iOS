import SwiftUI

/// 분류 아이콘. 글리프만 그리거나 둥근 타일에 얹어 그린다.
///
/// 쓰는 곳마다 타일 크기·모서리·배경이 달라 각자 그리고 있었다. 여기로 모으고
/// 화면은 아래 프리셋으로 부른다.
struct RecapCategoryIcon: View {
    /// 글리프를 얹는 둥근 판.
    struct Tile {
        let size: CGFloat
        let cornerRadius: CGFloat
        let color: Color
    }

    let category: CardCategory
    let glyphSize: CGFloat
    /// `nil`이면 타일 없이 글리프만 그린다.
    var tile: Tile?
    /// 기타에는 고유한 모양이 없다. 자리를 비워 둘 화면은 `false`를 준다.
    var drawsOtherCategory = true

    var body: some View {
        glyph
            .frame(width: tile?.size, height: tile?.size)
            .background(tile?.color)
            .clipShape(
                RoundedRectangle(cornerRadius: tile?.cornerRadius ?? 0, style: .continuous)
            )
    }

    /// 이 자리에 실제로 글리프가 그려지는지. 앞뒤 간격을 잡는 화면이 물어본다.
    var showsGlyph: Bool {
        category != .other || drawsOtherCategory
    }

    @ViewBuilder
    private var glyph: some View {
        if showsGlyph {
            RecapIconView(
                icon: .categoryIcon(for: category),
                size: glyphSize,
                color: RecapPresentation.categoryDisplay(for: category).dotColor
            )
        }
    }
}

extension RecapCategoryIcon {
    /// 홈 즐겨찾기 카드의 칩 안.
    static func chip(_ category: CardCategory) -> Self {
        Self(
            category: category,
            glyphSize: 16,
            tile: Tile(size: 24, cornerRadius: 10, color: Color.recapBackground)
        )
    }

    /// 보관함 폴더형 카드의 폴더 그림 위. 기타는 자리를 비운다.
    static func folderCard(_ category: CardCategory) -> Self {
        Self(
            category: category,
            glyphSize: 16,
            tile: Tile(size: 30, cornerRadius: 10, color: Color.recapBackground),
            drawsOtherCategory: false
        )
    }

    /// 보관함 목록형 행.
    static func folderRow(_ category: CardCategory) -> Self {
        Self(
            category: category,
            glyphSize: 30,
            tile: Tile(size: 61, cornerRadius: 27, color: Color.recapCategorySurface)
        )
    }

    /// 홈 자주 저장한 유형.
    static func frequentType(_ category: CardCategory) -> Self {
        Self(
            category: category,
            glyphSize: 30,
            tile: Tile(size: 71, cornerRadius: 27, color: Color.recapCategorySurface)
        )
    }

    /// 보관함 상세 헤더. 타일 없이 글리프만 그리고, 기타는 자리를 비운다.
    static func detailHeader(_ category: CardCategory) -> Self {
        Self(
            category: category,
            glyphSize: 20,
            tile: nil,
            drawsOtherCategory: false
        )
    }
}

#if DEBUG
#Preview("분류 아이콘") {
    VStack(spacing: 16) {
        HStack(spacing: 12) {
            RecapCategoryIcon.chip(.shopping)
            RecapCategoryIcon.chip(.other)
            RecapCategoryIcon.folderCard(.shopping)
            RecapCategoryIcon.folderCard(.other)
            RecapCategoryIcon.detailHeader(.shopping)
        }

        HStack(spacing: 12) {
            RecapCategoryIcon.folderRow(.schedule)
            RecapCategoryIcon.folderRow(.other)
            RecapCategoryIcon.frequentType(.other)
        }
    }
    .padding()
}
#endif
