//
//  InMemoryAPIKeyStore.swift
//  AIAssistantMacOSApp
//
//  Created by Patricio Sepúlveda Heise on 29-06-23.
//

import AIAssistant

class InMemoryAPIKeyStore: APIKeyLoader, APIKeySaver {
    var apiKey: String = ""

    func load() throws -> String {
        return apiKey
    }

    func save(_ value: String) throws {
        apiKey = value
    }
}
