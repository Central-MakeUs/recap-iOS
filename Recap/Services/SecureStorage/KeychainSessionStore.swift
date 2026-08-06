import Foundation
import Security

protocol KeychainDataStoring {
    func read(service: String, account: String) throws -> Data?
    func write(_ data: Data, service: String, account: String) throws
    func delete(service: String, account: String) throws
}

nonisolated enum SecureStorageKeychainConstants {
    static let service = "com.centralmakeus.recap.secure-storage"
    static let deviceIDAccount = "installation-device-id"
    static let serverTokenAccount = "server-token-record"
    /// Security 프레임워크의 불변 CFString 상수. Sendable 표기가 없을 뿐 변경되지 않는다.
    nonisolated(unsafe) static let accessible = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
}

final class KeychainSessionStore: SecureSessionStoring {
    private let keychain: KeychainDataStoring
    private let service: String
    private let deviceIDAccount: String
    private let serverTokenAccount: String
    private let makeDeviceID: () -> String
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(
        keychain: KeychainDataStoring = SystemKeychainDataStore(),
        service: String = SecureStorageKeychainConstants.service,
        deviceIDAccount: String = SecureStorageKeychainConstants.deviceIDAccount,
        serverTokenAccount: String = SecureStorageKeychainConstants.serverTokenAccount,
        makeDeviceID: @escaping () -> String = { UUID().uuidString }
    ) {
        self.keychain = keychain
        self.service = service
        self.deviceIDAccount = deviceIDAccount
        self.serverTokenAccount = serverTokenAccount
        self.makeDeviceID = makeDeviceID

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        self.encoder = encoder

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder
    }

    func deviceID() throws -> String {
        if let storedData = try keychain.read(service: service, account: deviceIDAccount) {
            guard let storedID = String(data: storedData, encoding: .utf8), !storedID.isEmpty else {
                throw SecureStorageError.invalidStoredDeviceID
            }
            return storedID
        }

        let generatedID = makeDeviceID()
        guard let generatedData = generatedID.data(using: .utf8), !generatedID.isEmpty else {
            throw SecureStorageError.invalidStoredDeviceID
        }

        try keychain.write(generatedData, service: service, account: deviceIDAccount)
        return generatedID
    }

    func saveServerTokenRecord(_ record: ServerTokenRecord) throws {
        let data: Data
        do {
            data = try encoder.encode(record)
        } catch {
            throw SecureStorageError.encodingFailed
        }

        try keychain.write(data, service: service, account: serverTokenAccount)
    }

    func loadServerTokenRecord() throws -> ServerTokenRecord? {
        guard let data = try keychain.read(service: service, account: serverTokenAccount) else {
            return nil
        }

        do {
            return try decoder.decode(ServerTokenRecord.self, from: data)
        } catch {
            throw SecureStorageError.decodingFailed
        }
    }

    func deleteServerTokenRecord() throws {
        try keychain.delete(service: service, account: serverTokenAccount)
    }
}

final class SystemKeychainDataStore: KeychainDataStoring {
    private let accessGroup: String?

    init(
        accessGroup: String? = Bundle.main.object(
            forInfoDictionaryKey: "KEYCHAIN_ACCESS_GROUP"
        ) as? String
    ) {
        self.accessGroup = accessGroup?.isEmpty == false ? accessGroup : nil
    }

    func read(service: String, account: String) throws -> Data? {
        var query = baseQuery(service: service, account: account)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecItemNotFound, accessGroup != nil {
            return try migrateLegacyItemIfPresent(service: service, account: account)
        }

        if status == errSecItemNotFound {
            return nil
        }

        guard status == errSecSuccess else {
            throw SecureStorageError.keychain(status: status)
        }

        return result as? Data
    }

    func write(_ data: Data, service: String, account: String) throws {
        let query = baseQuery(service: service, account: account)
        let update: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: SecureStorageKeychainConstants.accessible
        ]

        let updateStatus = SecItemUpdate(query as CFDictionary, update as CFDictionary)
        if updateStatus == errSecSuccess {
            return
        }

        guard updateStatus == errSecItemNotFound else {
            throw SecureStorageError.keychain(status: updateStatus)
        }

        var addQuery = query
        addQuery[kSecValueData as String] = data
        addQuery[kSecAttrAccessible as String] = SecureStorageKeychainConstants.accessible

        let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
        guard addStatus == errSecSuccess else {
            throw SecureStorageError.keychain(status: addStatus)
        }
    }

    func delete(service: String, account: String) throws {
        let status = SecItemDelete(baseQuery(service: service, account: account) as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw SecureStorageError.keychain(status: status)
        }
    }

    private func baseQuery(service: String, account: String) -> [String: Any] {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        if let accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }
        return query
    }

    private func migrateLegacyItemIfPresent(service: String, account: String) throws -> Data? {
        var legacyQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: CFTypeRef?
        let status = SecItemCopyMatching(legacyQuery as CFDictionary, &result)
        if status == errSecItemNotFound {
            return nil
        }
        guard status == errSecSuccess, let data = result as? Data else {
            throw SecureStorageError.keychain(status: status)
        }

        try write(data, service: service, account: account)
        legacyQuery.removeValue(forKey: kSecReturnData as String)
        legacyQuery.removeValue(forKey: kSecMatchLimit as String)
        SecItemDelete(legacyQuery as CFDictionary)
        return data
    }
}
