//
//  Completion.swift
//  AIAssistant
//
//  Created by Patricio Sepúlveda Heise on 04-07-23.
//

import Foundation

public struct Completion: Equatable {
    public let content: String

    public init(_ content: String) {
        self.content = content
    }
}
