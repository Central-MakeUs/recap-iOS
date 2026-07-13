//
//  AppConfiguration.swift
//  Recap
//

import Foundation

struct AppConfiguration: Sendable {
    let backendBaseURL: URL
    let kakaoNativeAppKey: String?

    static func live(bundle: Bundle = .main) -> AppConfiguration {
        AppConfiguration(infoDictionary: bundle.infoDictionary ?? [:])
    }

    init(infoDictionary: [String: Any]) {
        backendBaseURL = URL(string: "https://re-cap.duckdns.org")!
        kakaoNativeAppKey = Self.nonEmptyString(
            infoDictionary["KAKAO_NATIVE_APP_KEY"] as? String
        )
    }

    private static func nonEmptyString(_ value: String?) -> String? {
        guard let value else { return nil }

        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedValue.isEmpty ? nil : trimmedValue
    }
}
