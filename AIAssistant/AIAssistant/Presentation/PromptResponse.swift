//
//  PromptResponse.swift
//  AIAssistant
//
//  Created by Patricio Sepúlveda Heise on 20-06-23.
//

import Foundation

public struct PromptResponse: Equatable, Identifiable {
    public var id: Int
    public var prompt: String
    public var response: String

    public init(id: Int, prompt: String, response: String) {
        self.id = id
        self.prompt = prompt
        self.response = response
    }
}
