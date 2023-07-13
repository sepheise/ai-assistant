//
//  KeychainAPIKeyStore.swift
//  AIAssistant
//
//  Created by Patricio Sepúlveda Heise on 23-06-23.
//

import Foundation
import Security

public actor KeychainAPIKeyStore {
    public enum Error: Swift.Error {
        case invalidValue
        case saveFailure
        case loadFailure
        case updateFailure
        case deleteFailure
        case unknownError
    }

    private let key: String
    private let keychainAccessGroup: String = "B8AGE2A2NW.AIAssistant"

    public init(key: String = "com.sepheise.AIAssistant.apiKey") {
        self.key = key
    }

    private func add(_ query: [String: Any], _ data: Data) throws {
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == noErr else {
            throw Error.saveFailure
        }
    }

    private func update(_ query: [String: Any], _ data: Data) throws {
        let attributesToUpdate: [String: Any] = [
            String(kSecValueData): data
        ]

        let status = SecItemUpdate(query as CFDictionary, attributesToUpdate as CFDictionary)
        guard status == noErr else {
            throw Error.updateFailure
        }
    }
}

extension KeychainAPIKeyStore: APIKeySaver {
    public func save(_ value: String) async throws {
        guard let data = value.data(using: .utf8) else {
            throw Error.invalidValue
        }

        let query: [String: Any] = [
            String(kSecClass): kSecClassGenericPassword,
            String(kSecAttrAccount): key,
            String(kSecAttrAccessGroup): keychainAccessGroup,
            String(kSecUseDataProtectionKeychain): kCFBooleanTrue as Any,
            String(kSecValueData): data
        ]
        let status = SecItemCopyMatching(query as CFDictionary, nil)

        switch status {
        case errSecSuccess:
            try update(query, data)
        case errSecItemNotFound:
            try add(query, data)
        default:
            throw Error.unknownError
        }
    }
}

extension KeychainAPIKeyStore: APIKeyLoader {
    public func load() async throws -> String {
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: key,
            kSecAttrAccessGroup: keychainAccessGroup,
            kSecUseDataProtectionKeychain: kCFBooleanTrue as Any,
            kSecReturnData: kCFBooleanTrue as Any,
            kSecMatchLimit: kSecMatchLimitOne
        ] as CFDictionary

        var queryResult: AnyObject?
        let status = SecItemCopyMatching(query, &queryResult)

        guard status == noErr, let data = queryResult as? Data else {
            throw Error.loadFailure
        }

        return String(decoding: data, as: UTF8.self)
    }
}

extension KeychainAPIKeyStore: APIKeyDeleter {
    public func delete() async throws {
        let query: [String: Any] = [
            String(kSecClass): kSecClassGenericPassword,
            String(kSecAttrAccount): key,
            String(kSecAttrAccessGroup): keychainAccessGroup,
            String(kSecUseDataProtectionKeychain): kCFBooleanTrue as Any
        ]

        let status = SecItemDelete(query as CFDictionary)

        guard status == errSecItemNotFound || status == noErr else {
            throw Error.deleteFailure
        }
    }
}
