//
//  Message.swift
//  AIAssistant
//
//  Created by Patricio Sepúlveda Heise on 31-05-23.
//

public struct Message: Equatable {
    public enum Role: CustomStringConvertible {
        case assistant
        case user

        public var description: String {
            switch self {
                case .assistant: return "assistant"
                case .user: return "user"
            }
        }
    }

    public let role: Role
    public let content: String

    public init(role: Role, content: String) {
        self.role = role
        self.content = content
    }
}
