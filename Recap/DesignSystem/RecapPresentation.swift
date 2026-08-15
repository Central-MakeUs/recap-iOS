import SwiftUI

enum RecapPresentation {
    struct TabItem {
        let title: String
        let systemImage: String
    }

    struct InitialRangeOption {
        let title: String
        let countText: String
        let isRecommended: Bool
    }

    struct CategoryDisplay {
        let title: String
        let subtitle: String
        let dotColor: Color
        let textColor: Color
        let symbolName: String
    }

    struct StatusDisplay {
        let title: String
        let message: String
        let iconName: String
        let progress: Double?
        let tint: Color
        let background: Color
    }

    static func tabItem(for tab: MainTab) -> TabItem {
        switch tab {
        case .home:
            TabItem(title: "홈", systemImage: "house.fill")
        case .archive:
            TabItem(title: "보관함", systemImage: "archivebox.fill")
        }
    }

    static func initialRangeOption(for range: InitialRange) -> InitialRangeOption {
        switch range {
        case .sevenDays:
            InitialRangeOption(title: "최근 7일", countText: "26개", isRecommended: false)
        case .thirtyDays:
            InitialRangeOption(title: "최근 30일", countText: "124개", isRecommended: true)
        case .threeMonths:
            InitialRangeOption(title: "최근 3개월", countText: "386개", isRecommended: false)
        }
    }

    static func categoryDisplay(for category: CardCategory) -> CategoryDisplay {
        switch category {
        case .shopping:
            CategoryDisplay(
                title: category.displayTitle,
                subtitle: "택배 반품 절차 · 노트북 가격 비교",
                dotColor: .categoryBlue500,
                textColor: .categoryBlue700,
                symbolName: "cart.fill"
            )
        case .place:
            CategoryDisplay(
                title: category.displayTitle,
                subtitle: "성수 카페 리스트 · 제주 맛집 후보",
                dotColor: .categoryRed500,
                textColor: .categoryRed700,
                symbolName: "key.fill"
            )
        case .schedule:
            CategoryDisplay(
                title: category.displayTitle,
                subtitle: "제주 숙소 예약 · 병원 예약 안내",
                dotColor: .categoryGreen500,
                textColor: .categoryGreen700,
                symbolName: "clock.fill"
            )
        case .knowledge:
            CategoryDisplay(
                title: category.displayTitle,
                subtitle: "연말정산 서류목록 · 파스타레시피",
                dotColor: .categoryYellow500,
                textColor: .categoryYellow700,
                symbolName: "lightbulb.fill"
            )
        case .content:
            CategoryDisplay(
                title: category.displayTitle,
                subtitle: "쇼코의 미소 독후감",
                dotColor: .categoryPink500,
                textColor: .categoryPink700,
                symbolName: "book.closed.fill"
            )
        case .benefits:
            CategoryDisplay(
                title: category.displayTitle,
                subtitle: "올리브영 팝업스토어 이벤트 · SKT 할인혜택",
                dotColor: .categoryMint500,
                textColor: .categoryMint700,
                symbolName: "star.fill"
            )
        case .capture:
            CategoryDisplay(
                title: category.displayTitle,
                subtitle: "주간 운동기록 · 헬스장 머신 사용법",
                dotColor: .categoryPurple500,
                textColor: .categoryPurple700,
                symbolName: "pencil"
            )
        case .career:
            CategoryDisplay(
                title: category.displayTitle,
                subtitle: "채용 공고, 지원 일정, 취업 정보",
                dotColor: .categoryOrange500,
                textColor: .categoryOrange700,
                symbolName: "person.fill"
            )
        case .other:
            CategoryDisplay(
                title: category.displayTitle,
                subtitle: "분류가 아직 확정되지 않은 카드",
                dotColor: Color.recapGray100,
                textColor: Color.recapGray500,
                symbolName: "folder.fill"
            )
        }
    }

    static func statusDisplay(for status: HomeStatus) -> StatusDisplay {
        switch status {
        case .loading:
            StatusDisplay(
                title: "홈 정보를 불러오고 있어요",
                message: "",
                iconName: "arrow.trianglehead.2.clockwise.rotate.90",
                progress: nil,
                tint: Color.recapGray300,
                background: Color.recapBackground
            )
        case .ready:
            StatusDisplay(
                title: "새 스크린샷을 정리할 준비가 됐어요",
                message: "스크린샷을 불러와 필요한 정보만 카드로 정리해보세요.",
                iconName: "sparkles",
                progress: nil,
                tint: Color.recapBlue300,
                background: Color.recapPrimarySoft
            )
        case .processing:
            StatusDisplay(
                title: "스크린샷을 정리하고 있어요",
                message: "필요한 정보를 찾고 카드로 만드는 중이에요.",
                iconName: "circle.dotted",
                progress: 0.67,
                tint: Color.recapBlue300,
                background: Color.recapPrimarySoft
            )
        case .complete:
            StatusDisplay(
                title: "먼저 3개를 정리했어요",
                message: "완성된 정보카드를 확인해보세요.",
                iconName: "checkmark",
                progress: nil,
                tint: Color.recapSuccess,
                background: Color.recapPrimarySoft
            )
        case .waiting:
            StatusDisplay(
                title: "아직 정리할 스크린샷이 없어요",
                message: "새 캡처가 생기면 여기서 바로 시작할 수 있어요.",
                iconName: "clock",
                progress: nil,
                tint: Color.recapGray300,
                background: Color.recapControlFill
            )
        case .failed:
            StatusDisplay(
                title: "스크린샷을 불러오지 못했어요",
                message: "잠시 후 다시 시도해주세요.",
                iconName: "exclamationmark.circle.fill",
                progress: nil,
                tint: .red,
                background: Color.red.opacity(0.08)
            )
        }
    }

}
