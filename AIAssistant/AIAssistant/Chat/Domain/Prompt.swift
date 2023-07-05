//
//  Prompt.swift
//  AIAssistant
//
//  Created by Patricio Sepúlveda Heise on 04-07-23.
//

import Foundation

public struct Prompt: Equatable {
    public let id: UUID
    public let content: String
    public let previousPrompts: [Prompt]
    public let completion: Completion?

    public init(id: UUID = UUID(), _ content: String, previousPrompts: [Prompt] = [], completion: Completion? = nil) {
        self.id = id
        self.content = content
        self.completion = completion
        self.previousPrompts = previousPrompts
    }
}
