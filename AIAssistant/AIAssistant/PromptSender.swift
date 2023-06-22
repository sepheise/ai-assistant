//
//  MessageSender.swift
//  AIAssistant
//
//  Created by Patricio Sepúlveda Heise on 31-05-23.
//

import Foundation

public protocol PromptSender {
    func send(prompt: String, previousMessages: [Message]) async throws -> PromptResponseStream
}

public typealias PromptResponseStream = AsyncThrowingStream<String, Error>

public enum SendPromptError: Error {
    case invalidInput
    case connectivity
    case unexpectedResponse
    case incompleteResponse
}
