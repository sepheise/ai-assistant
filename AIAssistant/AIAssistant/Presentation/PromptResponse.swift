//
//  PromptResponse.swift
//  AIAssistant
//
//  Created by Patricio Sepúlveda Heise on 20-06-23.
//

public struct PromptResponse: Equatable {
    public var prompt: String
    public var response: String

    public init(prompt: String, response: String) {
        self.prompt = prompt
        self.response = response
    }
}
