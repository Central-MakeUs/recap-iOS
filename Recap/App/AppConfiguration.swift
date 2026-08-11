//
//  AppConfiguration.swift
//  Recap
//

import Foundation

enum AppRuntimeProfile: String, Sendable {
    #if DEBUG
    case mock
    #endif
    case live
}

struct AppConfiguration: Sendable {
    private static let productionBackendBaseURL = URL(string: "https://re-cap.duckdns.org")!

    let runtimeProfile: AppRuntimeProfile
    let backendBaseURL: URL
    let kakaoNativeAppKey: String?

    static func live(bundle: Bundle = .main) -> AppConfiguration {
        AppConfiguration(infoDictionary: bundle.infoDictionary ?? [:])
    }

    init(infoDictionary: [String: Any]) {
        runtimeProfile = Self.runtimeProfile(
            from: infoDictionary["APP_RUNTIME_PROFILE"] as? String
        )
        backendBaseURL = Self.backendBaseURL(
            from: infoDictionary["BACKEND_BASE_URL"] as? String
        )
        kakaoNativeAppKey = Self.nonEmptyString(
            infoDictionary["KAKAO_NATIVE_APP_KEY"] as? String
        )
    }

    private static func runtimeProfile(from value: String?) -> AppRuntimeProfile {
        guard
            let value = nonEmptyString(value)?.lowercased(),
            let profile = AppRuntimeProfile(rawValue: value)
        else {
            return .live
        }

        return profile
    }

    private static func backendBaseURL(from value: String?) -> URL {
        guard
            let value = nonEmptyString(value),
            let url = URL(string: value),
            let scheme = url.scheme,
            ["http", "https"].contains(scheme),
            url.host != nil
        else {
            return productionBackendBaseURL
        }

        return url
    }

    private static func nonEmptyString(_ value: String?) -> String? {
        guard let value else { return nil }

        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedValue.isEmpty ? nil : trimmedValue
    }
}
