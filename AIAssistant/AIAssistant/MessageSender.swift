//
//  MessageSender.swift
//  AIAssistant
//
//  Created by Patricio Sepúlveda Heise on 31-05-23.
//

import Foundation

public protocol MessageSender {
    func send(text: String) async throws -> ResponseTextStream
}

public typealias ResponseTextStream = AsyncThrowingStream<String, Error>

public enum SendMessageError: Error {
    case invalidInput
    case connectivity
    case unexpectedResponse
    case incompleteResponse
}
