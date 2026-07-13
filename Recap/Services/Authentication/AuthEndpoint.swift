//
//  AuthEndpoint.swift
//  Recap
//

import Foundation

enum AuthEndpoint {
    static func login(
        provider: AuthProvider,
        deviceId: String,
        providerToken: String
    ) throws -> APIEndpoint {
        try APIEndpoint.postJSON(
            path: path(for: provider),
            body: OAuthLoginRequest(deviceId: deviceId, providerToken: providerToken),
            cachePolicy: .reloadIgnoringLocalCacheData
        )
    }

    static func kakaoLogin(deviceId: String, providerToken: String) throws -> APIEndpoint {
        try login(provider: .kakao, deviceId: deviceId, providerToken: providerToken)
    }

    static func appleLogin(deviceId: String, providerToken: String) throws -> APIEndpoint {
        try login(provider: .apple, deviceId: deviceId, providerToken: providerToken)
    }

    private static func path(for provider: AuthProvider) -> String {
        switch provider {
        case .kakao:
            return "/api/v1/auth/oauth/kakao/login"
        case .apple:
            return "/api/v1/auth/oauth/apple/login"
        }
    }
}
