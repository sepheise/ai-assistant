//
//  Completion.swift
//  AIAssistant
//
//  Created by Patricio Sepúlveda Heise on 04-07-23.
//

import Foundation

public struct Completion {
    public let id: UUID
    public let content: String

    public init(id: UUID = UUID(), _ content: String) {
        self.id = id
        self.content = content
    }
}
