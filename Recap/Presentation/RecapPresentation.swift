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

    struct CollectionDisplay {
        let title: String
        let subtitle: String
        let dotColor: Color
    }

    struct StatusDisplay {
        let title: String
        let message: String
        let iconName: String
        let progress: Double?
        let tint: Color
        let background: Color
    }

    struct SettingsItem {
        let title: String
        let systemImage: String
    }

    static func tabItem(for tab: MainTab) -> TabItem {
        switch tab {
        case .home:
            TabItem(title: "홈", systemImage: "square.fill")
        case .collection:
            TabItem(title: "컬렉션", systemImage: "square.grid.2x2")
        case .myPage:
            TabItem(title: "마이페이지", systemImage: "person.crop.circle")
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

    static func collectionDisplay(for kind: CollectionKind) -> CollectionDisplay {
        switch kind {
        case .revisit:
            CollectionDisplay(
                title: "다시 볼 정보",
                subtitle: "예약, 일정, 주소, 공지",
                dotColor: RecapTheme.ColorToken.primary
            )
        case .comparison:
            CollectionDisplay(
                title: "비교 리스트",
                subtitle: "상품, 맛집, 여행지, 숙소",
                dotColor: Color(red: 0.360, green: 0.720, blue: 0.780)
            )
        case .archive:
            CollectionDisplay(
                title: "보관·기록",
                subtitle: "결제, 주문, 대화, 오류",
                dotColor: Color(red: 0.520, green: 0.440, blue: 0.930)
            )
        case .reference:
            CollectionDisplay(
                title: "참고 자료",
                subtitle: "디자인, 글, 인사이트, 기획 자료",
                dotColor: Color(red: 0.880, green: 0.620, blue: 0.220)
            )
        }
    }

    static func statusDisplay(for status: HomeStatus) -> StatusDisplay {
        switch status {
        case .ready:
            StatusDisplay(
                title: "새로 저장되는 스크린샷은 자동으로 정리돼요",
                message: "정리된 카드는 최근 정리된 카드와 컬렉션에서 확인할 수 있어요",
                iconName: "power",
                progress: nil,
                tint: RecapTheme.ColorToken.primary,
                background: RecapTheme.ColorToken.primaryLight
            )
        case .processing:
            StatusDisplay(
                title: "새로운 스크린샷 3개를 정리하고 있어요",
                message: "텍스트를 추출하고 핵심 정보를 정리하는 중이에요",
                iconName: "circle.fill",
                progress: 0.67,
                tint: RecapTheme.ColorToken.primary,
                background: RecapTheme.ColorToken.primaryLight
            )
        case .complete:
            StatusDisplay(
                title: "새로운 카드 3개가 정리되었어요",
                message: "최근 정리된 카드에서 바로 확인할 수 있어요",
                iconName: "checkmark",
                progress: nil,
                tint: RecapTheme.ColorToken.primary,
                background: RecapTheme.ColorToken.primaryLight
            )
        case .waiting:
            StatusDisplay(
                title: "정리 대기 중인 스크린샷 2개가 있어요",
                message: "정리 가능성이 확인되면 순서대로 카드로 정리됩니다",
                iconName: "clock",
                progress: nil,
                tint: RecapTheme.ColorToken.textTertiary,
                background: Color(red: 0.955, green: 0.965, blue: 0.980)
            )
        }
    }

    static func settingsItem(for route: SettingsRoute) -> SettingsItem {
        switch route {
        case .permissions:
            SettingsItem(title: "권한 설정", systemImage: "photo.on.rectangle")
        case .dataPolicy:
            SettingsItem(title: "데이터 관리", systemImage: "tray.full")
        case .help:
            SettingsItem(title: "도움말", systemImage: "questionmark.circle")
        }
    }
}
