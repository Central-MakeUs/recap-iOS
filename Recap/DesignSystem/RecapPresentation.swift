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
