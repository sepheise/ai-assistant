//
//  ChatModel.swift
//  AIAssistant
//
//  Created by Patricio Sepúlveda Heise on 17-06-23.
//

import Foundation

@MainActor
public class ChatModel: ObservableObject {
    @Published public var inputText: String = "" {
        didSet {
            checkCanSubmit()
        }
    }
    @Published public var promptResponse: PromptResponse? = nil
    @Published public var canSubmit: Bool = false
    @Published public var errorMessage: String = ""
    @Published public var promptResponses: [PromptResponse] = []

    private var isProcessing: Bool = false {
        didSet {
            checkCanSubmit()
        }
    }

    private var currentResponseText: String = ""

    private let promptSender: PromptSender

    public init(promptSender: PromptSender) {
        self.promptSender = promptSender
    }

    public func submit() async {
        guard canSubmit else { return }

        isProcessing = true
        defer {
            isProcessing = false
        }

        do {
            let textStream = try await promptSender.send(prompt: inputText)

            for try await text in textStream {
                currentResponseText += text
                promptResponse = PromptResponse(prompt: inputText, response: currentResponseText)
            }

            promptResponses.append(PromptResponse(prompt: inputText, response: currentResponseText))

            inputText = ""
            currentResponseText = ""
        } catch {
            errorMessage = "Could not load prompt response"
        }
    }

    private func checkCanSubmit() {
        canSubmit = !inputText.isEmpty && !isProcessing
    }
}
