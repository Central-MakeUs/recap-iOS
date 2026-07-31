import Foundation

/// 앱 밖에서 열리는 안내 문서 링크를 한곳에서 관리한다.
nonisolated enum RecapExternalLink: String, CaseIterable, Identifiable, Sendable {
    case privacyPolicy
    case termsOfService
    case support

    var id: String { rawValue }

    var title: String {
        switch self {
        case .privacyPolicy: "개인정보 처리방침"
        case .termsOfService: "이용약관"
        case .support: "문의하기"
        }
    }

    var url: URL {
        switch self {
        case .privacyPolicy:
            URL(string: "https://iced-flame-bab.notion.site/Recap-3a7c6339ee0f80a7ae7fff3153eb5036")!
        case .termsOfService:
            URL(string: "https://iced-flame-bab.notion.site/Recap-3abc6339ee0f80dd8b66c305645d9dee")!
        case .support:
            URL(string: "https://iced-flame-bab.notion.site/Recap-3adc6339ee0f80299a44ee8a36edb1f6?pvs=74")!
        }
    }
}
