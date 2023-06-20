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
    var body: some Scene {
        WindowGroup {
            ChatView(store: ChatModel(promptSender: FakePromptSender()))
        }
    }
}
