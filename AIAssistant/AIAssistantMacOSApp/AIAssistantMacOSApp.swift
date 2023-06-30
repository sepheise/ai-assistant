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
                    model: ChatModel(
                        promptSender: OpenAIMessageSender(
                            client: URLSessionHTTPClient(),
                            url: URL(string: "https://api.openai.com/v1/completions")!,
                            apiKey: loadAPIKey()
                        )
                    )
                ),
                settingsView: SettingsView(
                    apiKeyLoader: apiKeyStore,
                    apiKeySaver: apiKeyStore
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
