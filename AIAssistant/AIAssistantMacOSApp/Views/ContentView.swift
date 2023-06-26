//
//  ContentView.swift
//  AIAssistantMacOSApp
//
//  Created by Patricio Sepúlveda Heise on 24-06-23.
//

import SwiftUI
import AIAssistant

struct ContentView: View {

    @MainActor
    struct Views {
        static var chatView: some View = ChatView(model: ChatModel(promptSender: FakePromptSender()))
            .navigationTitle("Chat")
        static var settingsView: some View = SettingsView()
            .navigationTitle("Settings")
    }

    var body: some View {
        NavigationSplitView(
            sidebar: {
                List {
                    NavigationLink("Chat") {
                        Views.chatView
                    }
                    NavigationLink("Settings") {
                        Views.settingsView
                    }
                }
            },
            detail: {
                Views.chatView
            })
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
