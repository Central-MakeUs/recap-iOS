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
        let textColor: Color
        let symbolName: String
        let sampleCount: Int
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

    static func collectionDisplay(for kind: CollectionKind) -> CollectionDisplay {
        switch kind {
        case .shopping:
            CollectionDisplay(
                title: "쇼핑 · 상품",
                subtitle: "빅뱅 콘서트, 노트북 구매",
                dotColor: .categoryBlue500,
                textColor: .categoryBlue700,
                symbolName: "cart.fill",
                sampleCount: 20
            )
        case .place:
            CollectionDisplay(
                title: "장소 · 맛집",
                subtitle: "가게, 여행지, 맛집 후보",
                dotColor: .categoryRed500,
                textColor: .categoryRed700,
                symbolName: "key.fill",
                sampleCount: 23
            )
        case .schedule:
            CollectionDisplay(
                title: "일정 · 예약",
                subtitle: "예약 확정, 병원, 일정 안내",
                dotColor: .categoryGreen500,
                textColor: .categoryGreen700,
                symbolName: "clock.fill",
                sampleCount: 10
            )
        case .knowledge:
            CollectionDisplay(
                title: "정보 · 지식",
                subtitle: "팁, 안내, 학습 자료",
                dotColor: .categoryYellow500,
                textColor: .categoryYellow700,
                symbolName: "lightbulb.fill",
                sampleCount: 12
            )
        case .content:
            CollectionDisplay(
                title: "책 · 콘텐츠",
                subtitle: "책, 문서, 영상, 아티클",
                dotColor: .categoryGray500,
                textColor: .categoryGray700,
                symbolName: "book.closed.fill",
                sampleCount: 1
            )
        case .benefits:
            CollectionDisplay(
                title: "혜택 · 이벤트",
                subtitle: "쿠폰, 이벤트, 혜택 정보",
                dotColor: .categoryMint500,
                textColor: .categoryMint700,
                symbolName: "star.fill",
                sampleCount: 5
            )
        case .capture:
            CollectionDisplay(
                title: "기록 · 캡처",
                subtitle: "메모, 대화, 보관용 캡처",
                dotColor: .categoryPurple500,
                textColor: .categoryPurple700,
                symbolName: "pencil",
                sampleCount: 12
            )
        case .career:
            CollectionDisplay(
                title: "채용 · 취업",
                subtitle: "채용 공고, 지원 일정, 취업 정보",
                dotColor: .categoryOrange500,
                textColor: .categoryOrange700,
                symbolName: "pencil",
                sampleCount: 12
            )
        case .other:
            CollectionDisplay(
                title: "기타",
                subtitle: "분류가 아직 확정되지 않은 카드",
                dotColor: Color.recapGray100,
                textColor: Color.recapGray500,
                symbolName: "folder.fill",
                sampleCount: 0
            )
        }
    }

    static func statusDisplay(for status: HomeStatus) -> StatusDisplay {
        switch status {
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

    static func settingsItem(for route: SettingsRoute) -> SettingsItem {
        switch route {
        case .accountManagement:
            SettingsItem(title: "계정 관리", systemImage: "person.crop.circle")
        case .notificationSettings:
            SettingsItem(title: "알림 설정", systemImage: "bell")
        case .dataManagement:
            SettingsItem(title: "데이터 관리", systemImage: "tray.full")
        case .usageGuide:
            SettingsItem(title: "이용 안내", systemImage: "info.circle")
        case .privacyPolicy:
            SettingsItem(title: "개인정보 처리 안내", systemImage: "lock.shield")
        case .support:
            SettingsItem(title: "문의하기", systemImage: "envelope")
        }
    }
}
