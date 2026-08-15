import SwiftUI

enum ArchiveDetailScope: Hashable {
    case favorites
    case category(CardCategory)

    var title: String {
        switch self {
        case .favorites:
            "즐겨찾기"
        case .category(let category):
            RecapPresentation.categoryDisplay(for: category).title
        }
    }

    var searchPlaceholder: String {
        "\(title) 보관함 내에서 검색"
    }

    var rowMetadata: RecapInformationCardRow.Metadata {
        switch self {
        case .favorites:
            .category
        case .category:
            .organizedDate
        }
    }

    var searchScope: SearchScope {
        switch self {
        case .favorites:
            .favorites
        case .category(.other):
            .other
        case .category(let category):
            .type(category)
        }
    }
}

struct ArchiveDetailNavigationHeader: View {
    let scope: ArchiveDetailScope
    @Binding var query: String
    let showsSearchField: Bool
    let showsSearchButton: Bool
    let onBack: () -> Void
    let onStartSearch: () -> Void
    let onCloseSearch: () -> Void

    var body: some View {
        Group {
            if showsSearchField {
                searchHeader
            } else {
                titleHeader
            }
        }
        .frame(height: showsSearchField ? 44 : 25)
    }

    private var titleHeader: some View {
        HStack(spacing: 0) {
            Button(action: onBack) {
                RecapIconView(icon: .back, size: 24, color: Color.recapGray900)
            }
            .buttonStyle(.plain)

            scopeIcon

            Text(scope.title)
                .font(RecapFont.pretendard(size: 18, weight: .semibold))
                .tracking(-0.36)
                .foregroundStyle(Color.recapGray900)
                .padding(.leading, titleLeadingPadding)

            Spacer(minLength: 8)

            if showsSearchButton {
                Button(action: onStartSearch) {
                    RecapIconView(icon: .search, size: 24, color: Color.recapGray900)
                }
                .buttonStyle(.plain)
            }
        }
    }

    @ViewBuilder
    private var scopeIcon: some View {
        switch scope {
        case .favorites:
            RecapIconView(icon: .star, size: 20, color: Color.recapBlue300)
                .padding(.leading, 13)
        case .category(let category):
            RecapCategoryIcon.detailHeader(category)
                .padding(.leading, 13)
        }
    }

    /// 글리프가 없으면 아이콘 자리가 통째로 사라지므로(빈 뷰에는 패딩도 붙지 않는다)
    /// 제목이 그 앞 여백까지 맡는다.
    private var titleLeadingPadding: CGFloat {
        switch scope {
        case .favorites:
            10
        case .category(let category):
            RecapCategoryIcon.detailHeader(category).showsGlyph ? 10 : 13
        }
    }

    private var searchHeader: some View {
        HStack(spacing: 8) {
            SearchBar(
                text: $query,
                placeholder: scope.searchPlaceholder,
                focusesOnAppear: true
            )
            .frame(height: 44)

            Button(action: onCloseSearch) {
                RecapIconView(icon: .cancel, size: 24, color: Color.recapGray500)
            }
            .buttonStyle(.plain)
        }
    }
}

struct ArchiveDetailEmptyState: View {
    let scope: ArchiveDetailScope
    var onImportScreenshots: () -> Void = {}

    var body: some View {
        VStack(spacing: 0) {
            if scope == .favorites {
                RecapFavoriteEmptyIllustration()

                Text("아직 즐겨찾기한 스크린샷이 없어요")
                    .padding(.top, 20)

                Text("정리할 스크린샷을 불러오거나\n갤러리에서 공유해주세요")
                    .font(RecapFont.pretendard(size: 14, weight: .regular))
                    .tracking(-0.28)
                    .lineSpacing(1)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.recapGray300)
                    .padding(.top, 13)

                ArchiveScreenshotImportButton(action: onImportScreenshots)
                    .padding(.top, 23)
            } else {
                RecapFolderEmptyIllustration()

                Text("이 폴더에 정리된 스크린샷이 없어요")
                    .padding(.top, 20)
            }
        }
        .font(RecapFont.pretendard(size: 16, weight: .semibold))
        .tracking(-0.32)
        .foregroundStyle(Color.recapGray300)
        .frame(maxWidth: .infinity)
    }
}

#if DEBUG
#Preview("보관함 상세 헤더") {
    @Previewable @State var query = ""

    ArchiveDetailNavigationHeader(
        scope: .category(.shopping),
        query: $query,
        showsSearchField: false,
        showsSearchButton: true,
        onBack: {},
        onStartSearch: {},
        onCloseSearch: {}
    )
    .padding()
}

#Preview("즐겨찾기 상세 헤더") {
    @Previewable @State var query = ""

    ArchiveDetailNavigationHeader(
        scope: .favorites,
        query: $query,
        showsSearchField: false,
        showsSearchButton: true,
        onBack: {},
        onStartSearch: {},
        onCloseSearch: {}
    )
    .padding()
}

#Preview("보관함 상세 검색 헤더") {
    @Previewable @State var query = ""

    ArchiveDetailNavigationHeader(
        scope: .category(.shopping),
        query: $query,
        showsSearchField: true,
        showsSearchButton: false,
        onBack: {},
        onStartSearch: {},
        onCloseSearch: {}
    )
    .padding()
}

#Preview("보관함 상세 빈 상태") {
    ArchiveDetailEmptyState(scope: .category(.shopping))
}

#Preview("즐겨찾기 빈 상태") {
    ArchiveDetailEmptyState(scope: .favorites)
}
#endif
