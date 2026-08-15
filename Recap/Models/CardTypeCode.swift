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

    var category: CardCategory {
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

    init?(category: CardCategory) {
        switch category {
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
