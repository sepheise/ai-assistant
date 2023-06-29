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

    var body: some View {
        NavigationSplitView(
            sidebar: {
                List {
                    NavigationLink("Chat") {
                        chatView
                            .navigationTitle("Chat")
                    }
                    NavigationLink("Settings") {
                        settingsView
                            .navigationTitle("Settings")
                    }
                }
            },
            detail: {
                chatView
                    .navigationTitle("Chat")
            })
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(
            chatView: ChatView(model: ChatModel(promptSender: FakePromptSender())),
            settingsView: SettingsView()
        )
    }
}
