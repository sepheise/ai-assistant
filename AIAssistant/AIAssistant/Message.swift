//
//  Message.swift
//  AIAssistant
//
//  Created by Patricio Sepúlveda Heise on 31-05-23.
//

public struct Message {
    public let role: String
    public let content: String

    public init(role: String, content: String) {
        self.role = role
        self.content = content
    }
}
