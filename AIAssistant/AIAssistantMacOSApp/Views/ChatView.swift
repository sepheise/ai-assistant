//
//  ChatView.swift
//  AIAssistantMacOSApp
//
//  Created by Patricio Sepúlveda Heise on 17-06-23.
//

import SwiftUI
import AIAssistant

struct ChatView: View {
    @ObservedObject private var chatViewModel: ChatViewModel

    init(chatViewModel: ChatViewModel) {
        self.chatViewModel = chatViewModel
    }

    var body: some View {
        VStack(alignment: .leading) {
            PromptsAndResponsesView(promptResponses: $chatViewModel.promptResponses)
            Spacer()
            PromptTextInputView(
                inputText: $chatViewModel.inputText,
                canSubmit: $chatViewModel.canSubmit,
                submit: chatViewModel.submit
            )
        }
    }
}

struct ChatView_Previews: PreviewProvider {
    static var previews: some View {
        ChatView(chatViewModel: ChatViewModel(promptSender: FakePromptSender()))
    }
}
