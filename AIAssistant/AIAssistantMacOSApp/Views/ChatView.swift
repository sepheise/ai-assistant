//
//  ChatView.swift
//  AIAssistantMacOSApp
//
//  Created by Patricio Sepúlveda Heise on 17-06-23.
//

import SwiftUI
import AIAssistant

struct ChatView: View {
    @ObservedObject private var model: ChatModel

    init(model: ChatModel) {
        self.model = model
    }

    var body: some View {
        VStack(alignment: .leading) {
            if !model.promptResponses.isEmpty {
                PromptsAndResponsesView(promptResponses: $model.promptResponses)
            }
            Spacer()
            PromptTextInputView(
                inputText: $model.inputText,
                canSubmit: $model.canSubmit,
                submit: model.submit
            )
        }
    }
}

struct ChatView_Previews: PreviewProvider {
    static var previews: some View {
        ChatView(model: ChatModel(promptSender: FakePromptSender()))
    }
}
