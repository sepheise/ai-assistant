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
    @Published public var errorMessage: String
    @Published public var prompts: [Prompt] = []

    private var isProcessing: Bool = false {
        didSet {
            checkCanSubmit()
        }
    }

    private var currentResponseText: String = ""

    private let promptSender: PromptSender

    public init(promptSender: PromptSender, errorMessage: String = "") {
        self.promptSender = promptSender
        self.errorMessage = errorMessage
    }

    public func submit() async {
        guard canSubmit else { return }

        isProcessing = true
        defer {
            isProcessing = false
        }

        do {
            let promptId = UUID()
            let prompt = Prompt(id: promptId, inputText, previousPrompts: prompts)
            inputText = ""
            let promptIndex = prompts.count
            prompts.append(prompt)

            let textStream = try await promptSender.send(prompt: prompt)
            for try await text in textStream {
                currentResponseText += text
                let partialCompletion = Completion(currentResponseText)
                let updatedPrompt = Prompt(
                    id: promptId,
                    prompt.content,
                    completion: partialCompletion
                )
                prompts[promptIndex] = updatedPrompt
            }

            currentResponseText = ""
        } catch {
            errorMessage = "Could not load prompt response"
        }
    }

    private func checkCanSubmit() {
        canSubmit = !inputText.isEmpty && !isProcessing
    }
}
