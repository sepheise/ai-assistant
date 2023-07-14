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
        ZStack(alignment: .top) {
            VStack(alignment: .leading) {
                PromptsAndCompletionsView(prompts: $chatViewModel.prompts)
                Spacer()
                PromptTextInputView(
                    inputText: $chatViewModel.inputText,
                    canSubmit: $chatViewModel.canSubmit,
                    submit: chatViewModel.submit
                )
            }
            if !chatViewModel.errorMessage.isEmpty {
                ErrorView(errorMessage: chatViewModel.errorMessage)
            }
        }
    }
}

struct ErrorView: View {
    let errorMessage: String

    var body: some View {
        HStack(alignment: .top) {
            Text(errorMessage)
                .frame(width: .infinity, alignment: .topLeading)
                .font(.caption)
                .multilineTextAlignment(.leading)
                .padding(10)
                .foregroundColor(.black)
            Spacer()
        }
        .background(.yellow)
    }
}

struct ChatView_Previews: PreviewProvider {
    static let viewModel = ChatViewModel(promptSender: FakePromptSender())

    static let viewModelWithError = ChatViewModel(promptSender: FakePromptSender(), errorMessage: "Error")

    static var previews: some View {
        ChatView(chatViewModel: viewModel)

        ChatView(chatViewModel: viewModelWithError)
            .previewDisplayName("Chat View with Error")
    }
}
