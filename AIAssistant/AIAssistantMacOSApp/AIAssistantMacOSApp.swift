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

    var body: some Scene {
        WindowGroup {
            ContentView(
                chatView: ChatView(
                    chatViewModel: ChatViewModel(
                        promptSender: OpenAIMessageSender(
                            client: URLSessionHTTPClient(),
                            url: URL(string: "https://api.openai.com/v1/chat/completions")!,
                            apiKey: loadAPIKey()
                        )
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

func loadAPIKey() -> String {
    do {
        return try KeychainAPIKeyStore().load()
    } catch {
        return ""
    }
}
