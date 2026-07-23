//
//  AuthModels.swift
//  Recap
//

import Foundation

nonisolated enum AuthProvider: Equatable, Sendable {
    case kakao
    case apple
}

nonisolated struct OAuthLoginRequest: Encodable, Equatable, Sendable {
    let deviceId: String
    let providerToken: String
    let platform: String

    init(deviceId: String, providerToken: String, platform: String = "IOS") {
        self.deviceId = deviceId
        self.providerToken = providerToken
        self.platform = platform
    }
}

nonisolated struct AuthTokenResponse: Decodable, Equatable, Sendable {
    let accessToken: String
    let refreshToken: String
    let accessTokenExpiresAt: Date
}

typealias AuthLoginResponse = APIResponse<AuthTokenResponse>

nonisolated struct AuthRefreshRequest: Encodable, Equatable, Sendable {
    let refreshToken: String
}

nonisolated struct AuthLogoutRequest: Encodable, Equatable, Sendable {
    let refreshToken: String
}

typealias AuthLogoutResponse = APIResponse<EmptyResponse>
