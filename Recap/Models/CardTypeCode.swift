import Foundation

nonisolated enum CardTypeCode: String, Codable, Sendable {
    case job = "JOB"
    case shopping = "SHOPPING"
    case place = "PLACE"
    case schedule = "SCHEDULE"
    case knowledge = "KNOWLEDGE"
    case content = "CONTENT"
    case benefit = "BENEFIT"
    case record = "RECORD"
    case etc = "ETC"

    var collectionKind: CollectionKind {
        switch self {
        case .job:
            .career
        case .shopping:
            .shopping
        case .place:
            .place
        case .schedule:
            .schedule
        case .knowledge:
            .knowledge
        case .content:
            .content
        case .benefit:
            .benefits
        case .record:
            .capture
        case .etc:
            .other
        }
    }

    /// 분류 표시 이름의 원본은 도메인(`CollectionKind`) 한 곳이다.
    /// 와이어 코드가 같은 이름을 따로 정의해 두 벌이 어긋날 길을 없앤다.
    var displayTitle: String {
        collectionKind.displayTitle
    }

    init?(collectionKind: CollectionKind) {
        switch collectionKind {
        case .career:
            self = .job
        case .shopping:
            self = .shopping
        case .place:
            self = .place
        case .schedule:
            self = .schedule
        case .knowledge:
            self = .knowledge
        case .content:
            self = .content
        case .benefits:
            self = .benefit
        case .capture:
            self = .record
        case .other:
            self = .etc
        }
    }
}
