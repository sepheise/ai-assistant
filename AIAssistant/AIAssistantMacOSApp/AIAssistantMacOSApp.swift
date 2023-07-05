//
//  AIAssistantMacOSAppApp.swift
//  AIAssistantMacOSApp
//
//  Created by Patricio Sepúlveda Heise on 09-06-23.
//

import SwiftUI
import AIAssistant

@main
struct AIAssistantMacOSApp: App {
    private let apiKeyStore = KeychainAPIKeyStore()

    private func makePromptSender() -> PromptSender {
        return OpenAIMessageSenderWithKeyLoader(
            client: URLSessionHTTPClient(),
            url: URL(string: "https://api.openai.com/v1/chat/completions")!,
            apiKeyLoader: apiKeyStore
        )
    }

    var body: some Scene {
        WindowGroup {
            ContentView(
                chatView: ChatView(
                    chatViewModel: ChatViewModel(
                        promptSender: makePromptSender()
                    )
                ),
                settingsView: SettingsView(
                    viewModel: SettingsViewModel(
                        apiKeyLoader: apiKeyStore,
                        apiKeySaver: apiKeyStore
                    )
                )
            )
        }
    }
}

private class OpenAIMessageSenderWithKeyLoader: PromptSender {
    enum Error: Swift.Error {
        case cantLoadAPIKey
    }

    private let client: HTTPClient
    private let url: URL
    private let apiKeyLoader: APIKeyLoader

    init(client: HTTPClient, url: URL, apiKeyLoader: APIKeyLoader) {
        self.client = client
        self.url = url
        self.apiKeyLoader = apiKeyLoader
    }

    func send(prompt: String, previousMessages: [Message]) async throws -> PromptResponseStream {
        guard let apiKey = try? apiKeyLoader.load() else {
            throw Error.cantLoadAPIKey
        }

        let openAIMessageSender = OpenAIPromptSender(client: client, url: url, apiKey: apiKey)
        return try await openAIMessageSender.send(prompt: prompt, previousMessages: previousMessages)
    }

    func send(prompt: AIAssistant.Prompt) async throws -> AIAssistant.PromptResponseStream {
        guard let apiKey = try? apiKeyLoader.load() else {
            throw Error.cantLoadAPIKey
        }

        let openAIMessageSender = OpenAIPromptSender(client: client, url: url, apiKey: apiKey)
        return try await openAIMessageSender.send(prompt: prompt)
    }
}
