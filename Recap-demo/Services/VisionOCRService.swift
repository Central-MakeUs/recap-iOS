import Foundation
import UIKit
import Vision

struct VisionOCRPayload {
    let text: String
    let averageConfidence: Float?
    let textBlockCount: Int
    let ocrDuration: TimeInterval
    let transformDuration: TimeInterval
}

enum VisionOCRError: LocalizedError {
    case invalidImageData
    case missingCGImage
    case noResult

    var errorDescription: String? {
        switch self {
        case .invalidImageData: "이미지 데이터를 읽을 수 없어요."
        case .missingCGImage: "OCR에 필요한 CGImage를 만들 수 없어요."
        case .noResult: "Vision OCR 결과가 비어 있어요."
        }
    }
}

struct VisionOCRService {
    func recognize(data: Data, settings: ExperimentSettings) async throws -> VisionOCRPayload {
        guard let image = UIImage(data: data) else { throw VisionOCRError.invalidImageData }
        guard let cgImage = image.cgImage else { throw VisionOCRError.missingCGImage }

        let request = VNRecognizeTextRequest()
        request.recognitionLevel = settings.recognitionLevel == .fast ? .fast : .accurate
        request.usesLanguageCorrection = settings.usesLanguageCorrection
        if settings.languageMode == .koreanEnglish {
            request.recognitionLanguages = ["ko-KR", "en-US"]
        } else {
            request.automaticallyDetectsLanguage = true
        }

        let ocrStart = Date()
        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: CGImagePropertyOrientation(image.imageOrientation), options: [:])
        try handler.perform([request])
        let ocrDuration = Date().timeIntervalSince(ocrStart)

        let transformStart = Date()
        guard let observations = request.results else { throw VisionOCRError.noResult }
        let candidates = observations.compactMap { $0.topCandidates(1).first }
        let text = candidates.map(\.string).joined(separator: "\n")
        let confidence = candidates.isEmpty ? nil : candidates.map(\.confidence).reduce(0, +) / Float(candidates.count)
        let transformDuration = Date().timeIntervalSince(transformStart)

        return VisionOCRPayload(text: text, averageConfidence: confidence, textBlockCount: observations.count, ocrDuration: ocrDuration, transformDuration: transformDuration)
    }
}

extension CGImagePropertyOrientation {
    init(_ orientation: UIImage.Orientation) {
        switch orientation {
        case .up: self = .up
        case .down: self = .down
        case .left: self = .left
        case .right: self = .right
        case .upMirrored: self = .upMirrored
        case .downMirrored: self = .downMirrored
        case .leftMirrored: self = .leftMirrored
        case .rightMirrored: self = .rightMirrored
        @unknown default: self = .up
        }
    }
}
