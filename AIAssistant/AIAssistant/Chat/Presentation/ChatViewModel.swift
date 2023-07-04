//
//  ChatViewModel.swift
//  AIAssistant
//
//  Created by Patricio Sepúlveda Heise on 17-06-23.
//

import Foundation

@MainActor
public class ChatViewModel: ObservableObject {
    @Published public var inputText: String = "" {
        didSet {
            checkCanSubmit()
        }
    }
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
            let previousMessages = messagesFromPromptResponses()
            let prompt = inputText
            inputText = ""
            let promptIndex = promptResponses.count
            promptResponses.append(PromptResponse(id: promptIndex, prompt: prompt, response: ""))

            let textStream = try await promptSender.send(prompt: prompt, previousMessages: previousMessages)
            for try await text in textStream {
                currentResponseText += text
                promptResponses[promptIndex] = PromptResponse(id: promptIndex, prompt: prompt, response: currentResponseText)
            }

            currentResponseText = ""
        } catch {
            errorMessage = "Could not load prompt response"
        }
    }

    private func checkCanSubmit() {
        canSubmit = !inputText.isEmpty && !isProcessing
    }

    private func messagesFromPromptResponses() -> [Message] {
        var messages: [Message] = []

        promptResponses.forEach { prompResponse in
            messages.append(Message(role: .user, content: prompResponse.prompt))
            messages.append(Message(role: .assistant, content: prompResponse.response))
        }

        return messages
    }
}