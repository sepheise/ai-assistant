//
//  APIKeyDeleter.swift
//  AIAssistant
//
//  Created by Patricio Sepúlveda Heise on 07-07-23.
//

public protocol APIKeyDeleter {
    func delete() async throws
}
