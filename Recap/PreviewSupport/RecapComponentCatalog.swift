#if DEBUG
import SwiftUI

struct RecapComponentCatalog: View {
    @State private var selectedTab = MainTab.home
    @State private var searchText = "검색어"
    @State private var inputText = "텍스트"
    @State private var archiveSort = ArchiveSort.latest

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 28) {
                chips
                categoryIcons
                informationCards
                homeCards
                buttons
                inputs
                searchAndFilter
                icons
                folders
                feedback
                bottomNavigation
            }
            .padding(16)
        }
        .background(Color.recapBackground)
    }

    private var chips: some View {
        VStack(alignment: .leading, spacing: 12) {
            catalogTitle("chips")
            RecapChip(configuration: .category(.shopping, size: .small))
            RecapChip(configuration: .category(.capture, size: .medium))
            RecapChip(configuration: .category(.schedule, size: .large))
            RecapChip(configuration: .category(.schedule, size: .large, isSelected: false))
            RecapChip(configuration: .recentSearch("검색어 01234"))
        }
    }

    private var categoryIcons: some View {
        VStack(alignment: .leading, spacing: 12) {
            catalogTitle("category")
            HStack {
                RecapCategoryIcon(category: .shopping)
                RecapCategoryIcon(category: .place, size: .large)
                RecapCategoryIcon(category: .schedule)
                RecapCategoryIcon(category: .knowledge, size: .large)
            }
        }
    }

    private var informationCards: some View {
        VStack(spacing: 0) {
            catalogTitle("card/category · card/nocategory")
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 12)
            RecapInformationCardRow(
        card: Card(snapshot: SampleData.cards[2]))
            RecapInformationCardRow(
        card: Card(snapshot: SampleData.cards[3]), selectionState: true)
            RecapInformationCardRow(
        card: Card(snapshot: SampleData.cards[4]), metadata: .organizedDate)
            RecapInformationCardRow(
        card: Card(snapshot: SampleData.cards[1]),
                metadata: .organizedDate,
                selectionState: true
            )
        }
    }

    private var homeCards: some View {
        VStack(alignment: .leading, spacing: 12) {
            catalogTitle("imagecard · card/home")
            HStack(alignment: .top) {
                RecapImageCard(
                    category: .capture,
                    assetName: SampleData.cards[3].thumbnailAssetName
                )
                RecapImageCard(
                    category: .shopping,
                    assetName: SampleData.cards[0].thumbnailAssetName,
                    isFavorite: true
                )
                RecapHomeRecentCard(card: Card(snapshot: SampleData.cards[2]))
                RecapHomeFavoriteCard(card: Card(snapshot: SampleData.cards[3]))
            }
        }
    }

    private var buttons: some View {
        VStack(alignment: .leading, spacing: 12) {
            catalogTitle("btn · btn/popup")
            RecapButton(title: "버튼", action: {})
            RecapButton(title: "아이콘 버튼", systemImage: "arrow.clockwise", action: {})
            RecapButton(title: "비활성 버튼", action: {}).disabled(true)
            RecapButton(title: "다시 불러오기", systemImage: "arrow.clockwise", style: .secondary, size: .medium, action: {})
                .frame(width: 155)
            RecapButton(title: "건너뛰기", style: .secondary, size: .small, action: {})
                .frame(width: 125)
            HStack {
                RecapPopupButton(title: "취소", style: .secondary, action: {})
                RecapPopupButton(title: "삭제", style: .destructive, action: {})
            }
        }
    }

    private var inputs: some View {
        VStack(alignment: .leading, spacing: 18) {
            catalogTitle("input")
            RecapTextInput(
                label: "레이블",
                text: $inputText,
                placeholder: "텍스트",
                characterLimit: 30
            )
            RecapTextArea(
                label: "레이블",
                text: $inputText,
                placeholder: "텍스트",
                characterLimit: 300
            )
            RecapActionInput(label: "레이블", value: "텍스트", actionTitle: "변경", action: {})
        }
    }

    private var searchAndFilter: some View {
        VStack(alignment: .leading, spacing: 12) {
            catalogTitle("searchfield · filter")
            SearchBar(text: .constant(""))
            SearchBar(text: $searchText)
            RecapSortToggleButton(title: archiveSort.title) {
                archiveSort = archiveSort.toggled
            }
        }
    }

    private var icons: some View {
        VStack(alignment: .leading, spacing: 12) {
            catalogTitle("icon")
            LazyVGrid(columns: Array(repeating: GridItem(.fixed(32)), count: 8), spacing: 8) {
                ForEach(RecapIcon.allCases) { icon in
                    RecapIconView(icon: icon)
                }
            }
        }
    }

    private var folders: some View {
        VStack(alignment: .leading, spacing: 12) {
            catalogTitle("folder · folder/list")
            RecapFolderCard(title: "쇼핑 · 상품", count: 12, category: .shopping)
            RecapFolderListRow(
                title: "쇼핑 · 상품",
                subtitle: "택배 반품 절차 · 노트북 가격 비교",
                count: 12,
                category: .shopping
            )
        }
    }

    private var feedback: some View {
        VStack(alignment: .leading, spacing: 12) {
            catalogTitle("toast · popup")
            RecapToast(style: .success, message: "로그인에 성공했어요.")
            RecapToast(style: .error, message: "로그인에 실패했어요.")
            RecapConfirmationDialog(
                title: "스크린샷을 삭제할까요?",
                message: "삭제한 스크린샷 정보는\n되돌릴 수 없어요.",
                cancelTitle: "취소",
                confirmTitle: "삭제",
                onCancel: {},
                onConfirm: {}
            )
        }
    }

    private var bottomNavigation: some View {
        VStack(alignment: .leading, spacing: 12) {
            catalogTitle("bottom nav")
            HStack {
                RecapTabSelector(
                    selection: selectedTab,
                    onSelect: { selectedTab = $0 }
                )
                Spacer()
                RecapUploadButton(action: {})
            }
        }
    }

    private func catalogTitle(_ title: String) -> some View {
        Text(title)
            .font(RecapFont.pretendard(size: 16, weight: .semibold))
            .foregroundStyle(Color.recapGray900)
    }
}

#Preview("Figma 공통 컴포넌트 전체") {
    RecapComponentCatalog()
}
#endif
