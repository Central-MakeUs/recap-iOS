import SwiftUI

enum ArchiveDetailScope: Hashable {
    case favorites
    case category(CollectionKind)

    var title: String {
        switch self {
        case .favorites:
            "즐겨찾기"
        case .category(let kind):
            RecapPresentation.collectionDisplay(for: kind).title
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

}

struct CollectionDetailNavigationHeader: View {
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
        case .category(let kind) where kind != .other:
            RecapIconView(
                icon: RecapIcon.categoryIcon(for: kind),
                size: 20,
                color: RecapPresentation.collectionDisplay(for: kind).dotColor
            )
            .padding(.leading, 13)
        case .category:
            EmptyView()
        }
    }

    private var titleLeadingPadding: CGFloat {
        switch scope {
        case .category(.other):
            13
        case .favorites, .category:
            10
        }
    }

    private var searchHeader: some View {
        HStack(spacing: 8) {
            SearchBar(
                text: $query,
                placeholder: scope.searchPlaceholder
            )
            .frame(height: 44)

            Button(action: onCloseSearch) {
                RecapIconView(icon: .cancel, size: 24, color: Color.recapGray500)
            }
            .buttonStyle(.plain)
        }
    }
}

struct CollectionDetailEmptyState: View {
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

#Preview("보관함 상세 헤더") {
    @Previewable @State var query = ""

    CollectionDetailNavigationHeader(
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

    CollectionDetailNavigationHeader(
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

    CollectionDetailNavigationHeader(
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
    CollectionDetailEmptyState(scope: .category(.shopping))
}

#Preview("즐겨찾기 빈 상태") {
    CollectionDetailEmptyState(scope: .favorites)
}
