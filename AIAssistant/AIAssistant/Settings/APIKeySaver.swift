//
//  APIKeySaver.swift
//  AIAssistant
//
//  Created by Patricio Sepúlveda Heise on 29-06-23.
//

public protocol APIKeySaver {
    func save(_ value: String) async throws
}
