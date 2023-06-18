//
//  ChatStore.swift
//  AIAssistant
//
//  Created by Patricio Sepúlveda Heise on 17-06-23.
//

import Foundation

public class ChatStore: ObservableObject {
    @Published public var inputText: String = "" {
        didSet {
            checkCanSubmit()
        }
    }
    @Published public var responseText: String = ""
    @Published public var canSubmit: Bool = false
    @Published public var errorMessage: String = ""

    private var isProcessing: Bool = false {
        didSet {
            checkCanSubmit()
        }
    }

    private let promptSender: PromptSender

    public init(promptSender: PromptSender) {
        self.promptSender = promptSender
    }

    public func submit() {
        guard canSubmit else { return }

        isProcessing = true
        Task {
            do {
                let textStream = try await promptSender.send(prompt: inputText)
                for try await text in textStream {
                    responseText += text
                }
            } catch {
                errorMessage = "Could not load prompt response"
            }

            isProcessing = false
            inputText = ""
        }
    }

    private func checkCanSubmit() {
        canSubmit = !inputText.isEmpty && !isProcessing
    }
}
