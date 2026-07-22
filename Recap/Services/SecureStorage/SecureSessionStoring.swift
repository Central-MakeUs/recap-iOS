import Foundation

protocol SecureSessionStoring {
    func deviceID() throws -> String
    func saveServerTokenRecord(_ record: ServerTokenRecord) throws
    func loadServerTokenRecord() throws -> ServerTokenRecord?
    func deleteServerTokenRecord() throws
}

nonisolated struct ServerTokenRecord: Codable, Equatable, Sendable {
    let accessToken: String
    let refreshToken: String
    let accessTokenExpiresAt: Date
}

nonisolated enum SecureStorageError: Error, Equatable {
    case invalidStoredDeviceID
    case encodingFailed
    case decodingFailed
    case keychain(status: OSStatus)
}
