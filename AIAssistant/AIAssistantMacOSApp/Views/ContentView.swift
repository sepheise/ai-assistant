//
//  ContentView.swift
//  AIAssistantMacOSApp
//
//  Created by Patricio Sepúlveda Heise on 24-06-23.
//

import SwiftUI
import AIAssistant

struct ContentView: View {
    let chatView: ChatView
    let settingsView: SettingsView

    private let chatViewTitle = "Chat"
    private let settingsViewTitle = "Settings"

    var body: some View {
        NavigationSplitView(
            sidebar: {
                List {
                    NavigationLink(chatViewTitle) {
                        chatView
                            .navigationTitle(chatViewTitle)
                    }
                    NavigationLink(settingsViewTitle) {
                        settingsView
                            .navigationTitle(settingsViewTitle)
                    }
                }
            },
            detail: {
                chatView
                    .navigationTitle(chatViewTitle)
            })
    }
}

struct ContentView_Previews: PreviewProvider {
    private static let inMemoryAPIKeyStore = InMemoryAPIKeyStore()

    static var previews: some View {
        ContentView(
            chatView: ChatView(chatViewModel: ChatViewModel(promptSender: FakePromptSender())),
            settingsView: SettingsView(
                viewModel: SettingsViewModel(
                    apiKeyLoader: inMemoryAPIKeyStore,
                    apiKeySaver: inMemoryAPIKeyStore,
                    apiKeyDeleter: inMemoryAPIKeyStore
                )
            )
        )
    }
}
