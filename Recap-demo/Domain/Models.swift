import Foundation

enum ExecutionMode: String, Codable, CaseIterable, Identifiable {
    case foreground
    case background

    var id: String { rawValue }
    var label: String { self == .foreground ? "포그라운드" : "백그라운드" }
}

enum OCRRecognitionLevel: String, Codable, CaseIterable, Identifiable {
    case fast
    case accurate

    var id: String { rawValue }
    var label: String { self == .fast ? "fast" : "accurate" }
}

enum RecognitionLanguageMode: String, Codable, CaseIterable, Identifiable {
    case automatic
    case koreanEnglish

    var id: String { rawValue }
    var label: String { self == .automatic ? "자동 감지" : "한국어 + 영어" }
}

enum ExperimentStatus: String, Codable {
    case ready
    case running
    case completed
    case cancelled
    case failed
}

enum OCRImageStatus: String, Codable {
    case pending
    case loading
    case recognizing
    case completed
    case failed
    case cancelled
}

enum OCRQuality: String, Codable, CaseIterable, Identifiable {
    case good
    case partial
    case unusable

    var id: String { rawValue }
    var label: String {
        switch self {
        case .good: "좋음"
        case .partial: "일부 오류"
        case .unusable: "사용 불가"
        }
    }
}

enum ClassificationConfidence: String, Codable, CaseIterable, Identifiable {
    case strong
    case weak
    case none

    var id: String { rawValue }
    var label: String {
        switch self {
        case .strong: "확신 높음"
        case .weak: "확신 낮음"
        case .none: "근거 없음"
        }
    }
}

enum ScreenshotCategory: String, Codable, CaseIterable, Identifiable, Hashable {
    case comparisonCandidate
    case actionRequired
    case reference
    case record
    case unclassified

    var id: String { rawValue }
    var label: String {
        switch self {
        case .comparisonCandidate: "비교할 후보"
        case .actionRequired: "챙겨야 할 정보"
        case .reference: "참고할 자료"
        case .record: "남겨둘 기록"
        case .unclassified: "분류하기 어려움"
        }
    }

    var shortLabel: String {
        switch self {
        case .comparisonCandidate: "비교"
        case .actionRequired: "챙김"
        case .reference: "참고"
        case .record: "기록"
        case .unclassified: "불가"
        }
    }
}

enum ScreenshotEligibility: String, Codable, CaseIterable, Identifiable {
    case confirmedScreenshot
    case acceptedByFallback
    case unsupported
    case unknown

    var id: String { rawValue }
    var label: String {
        switch self {
        case .confirmedScreenshot: "스크린샷 확인"
        case .acceptedByFallback: "fallback 허용"
        case .unsupported: "지원하지 않는 이미지"
        case .unknown: "확인 불가"
        }
    }
}

struct ExperimentSettings: Codable, Equatable {
    var executionMode: ExecutionMode = .foreground
    var recognitionLevel: OCRRecognitionLevel = .accurate
    var languageMode: RecognitionLanguageMode = .koreanEnglish
    var usesLanguageCorrection: Bool = true
    var memo: String = ""

    var summary: String {
        "\(executionMode.label) · \(recognitionLevel.label) · \(languageMode.label) · 교정 \(usesLanguageCorrection ? "ON" : "OFF")"
    }
}

struct OCRExperiment: Identifiable, Codable {
    let id: UUID
    let startedAt: Date
    var finishedAt: Date?
    var settings: ExperimentSettings
    var imageCount: Int
    var status: ExperimentStatus
    var results: [OCRImageResult]
    var totalDuration: TimeInterval?
    var firstResultDuration: TimeInterval?
    var backgroundEnteredAt: Date?
    var completedBeforeBackground: Int
    var completedInBackground: Int
    var systemInterrupted: Bool
    var userCancelled: Bool

    init(id: UUID = UUID(), startedAt: Date = Date(), settings: ExperimentSettings, imageCount: Int) {
        self.id = id
        self.startedAt = startedAt
        self.settings = settings
        self.imageCount = imageCount
        self.status = .ready
        self.results = []
        self.completedBeforeBackground = 0
        self.completedInBackground = 0
        self.systemInterrupted = false
        self.userCancelled = false
    }

    var succeededCount: Int { results.filter { $0.status == .completed }.count }
    var failedCount: Int { results.filter { $0.status == .failed }.count }
    var evaluatedCount: Int { results.filter { $0.actualCategory != nil }.count }
    var correctCount: Int {
        results.filter { result in
            guard let actual = result.actualCategory,
                  let predicted = result.classificationResult?.predictedCategory else { return false }
            return actual == predicted
        }.count
    }
    var incorrectCount: Int { max(0, evaluatedCount - correctCount) }
    var averageImageDuration: TimeInterval? {
        let values = results.compactMap(\.totalDuration)
        guard !values.isEmpty else { return nil }
        return values.reduce(0, +) / Double(values.count)
    }
    var maxImageDuration: TimeInterval? { results.compactMap(\.totalDuration).max() }
    var accuracy: Double? {
        guard evaluatedCount > 0 else { return nil }
        return Double(correctCount) / Double(evaluatedCount)
    }
}

struct OCRImageResult: Identifiable, Codable {
    let id: UUID
    let order: Int
    var imageData: Data?
    var thumbnailData: Data?
    var width: Int?
    var height: Int?
    var fileSize: Int64?
    var eligibility: ScreenshotEligibility
    var loadDuration: TimeInterval?
    var ocrDuration: TimeInterval?
    var transformDuration: TimeInterval?
    var totalDuration: TimeInterval?
    var recognizedText: String
    var averageConfidence: Float?
    var textBlockCount: Int
    var status: OCRImageStatus
    var errorMessage: String?
    var classificationResult: ClassificationResult?
    var actualCategory: ScreenshotCategory?
    var ocrQuality: OCRQuality?
    var evaluationMemo: String?

    init(order: Int, imageData: Data?, thumbnailData: Data?, width: Int?, height: Int?, fileSize: Int64?, eligibility: ScreenshotEligibility) {
        self.id = UUID()
        self.order = order
        self.imageData = imageData
        self.thumbnailData = thumbnailData
        self.width = width
        self.height = height
        self.fileSize = fileSize
        self.eligibility = eligibility
        self.recognizedText = ""
        self.textBlockCount = 0
        self.status = .pending
    }
}

struct ClassificationResult: Codable, Equatable {
    let predictedCategory: ScreenshotCategory
    let scores: [ScreenshotCategory: Int]
    let matchedRules: [MatchedRule]
    let extractedSignals: ExtractedSignals
    let isAmbiguous: Bool
    let confidence: ClassificationConfidence
    let winningScore: Int
    let scoreGap: Int

    init(
        predictedCategory: ScreenshotCategory,
        scores: [ScreenshotCategory: Int],
        matchedRules: [MatchedRule],
        extractedSignals: ExtractedSignals,
        isAmbiguous: Bool,
        confidence: ClassificationConfidence = .weak,
        winningScore: Int = 0,
        scoreGap: Int = 0
    ) {
        self.predictedCategory = predictedCategory
        self.scores = scores
        self.matchedRules = matchedRules
        self.extractedSignals = extractedSignals
        self.isAmbiguous = isAmbiguous
        self.confidence = confidence
        self.winningScore = winningScore
        self.scoreGap = scoreGap
    }

    private enum CodingKeys: String, CodingKey {
        case predictedCategory, scores, matchedRules, extractedSignals, isAmbiguous, confidence, winningScore, scoreGap
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        predictedCategory = try container.decode(ScreenshotCategory.self, forKey: .predictedCategory)
        scores = try container.decode([ScreenshotCategory: Int].self, forKey: .scores)
        matchedRules = try container.decode([MatchedRule].self, forKey: .matchedRules)
        extractedSignals = try container.decode(ExtractedSignals.self, forKey: .extractedSignals)
        isAmbiguous = try container.decode(Bool.self, forKey: .isAmbiguous)
        confidence = try container.decodeIfPresent(ClassificationConfidence.self, forKey: .confidence) ?? (isAmbiguous ? .weak : .strong)
        winningScore = try container.decodeIfPresent(Int.self, forKey: .winningScore) ?? 0
        scoreGap = try container.decodeIfPresent(Int.self, forKey: .scoreGap) ?? 0
    }
}

struct MatchedRule: Identifiable, Codable, Equatable {
    var id: String { "\(category.rawValue)-\(pattern)-\(score)" }
    let category: ScreenshotCategory
    let pattern: String
    let score: Int
}

struct ExtractedSignals: Codable, Equatable {
    var hasAmount: Bool = false
    var hasDate: Bool = false
    var hasFutureDate: Bool = false
    var hasTime: Bool = false
    var hasReservationNumber: Bool = false
    var hasOrderNumber: Bool = false
    var hasApprovalNumber: Bool = false
    var hasErrorCode: Bool = false
    var hasURL: Bool = false
}

struct SelectedScreenshot: Identifiable, Hashable {
    let id = UUID()
    var data: Data
    var width: Int?
    var height: Int?
    var fileSize: Int64
    var eligibility: ScreenshotEligibility
}
