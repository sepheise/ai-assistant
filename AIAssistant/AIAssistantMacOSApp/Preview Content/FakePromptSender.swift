//
//  FakePromptSender.swift
//  AIAssistantMacOSApp
//
//  Created by Patricio Sepúlveda Heise on 17-06-23.
//

import Foundation
import AIAssistant

class FakePromptSender: PromptSender {
    private let textArray: [String]

    init(textArray: [String] = ["Hello", " there", "!"]) {
        self.textArray = textArray
    }

    func send(prompt: AIAssistant.Prompt) async throws -> AIAssistant.PromptResponseStream {
        return PromptResponseStream { continuation in
            Task {
                for text in textArray {
                    try await Task.sleep(for: .seconds(0.2))
                    continuation.yield(with: .success(text))
                }
                continuation.finish()
            }
        }
    }    
}
