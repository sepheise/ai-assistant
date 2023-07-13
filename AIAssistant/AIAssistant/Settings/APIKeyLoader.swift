//
//  APIKeyLoader.swift
//  AIAssistant
//
//  Created by Patricio Sepúlveda Heise on 29-06-23.
//

public protocol APIKeyLoader {
    func load() async throws -> String
}
