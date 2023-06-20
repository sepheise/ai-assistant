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
                PromptAndResponsesView(promptResponses: $model.promptResponses)
            }
            Spacer()
            ZStack(alignment: .bottomTrailing) {
                TextEditor(text: $model.inputText)
                    .font(.body)
                    .padding(EdgeInsets(top: 21, leading: 20, bottom: 19, trailing: 15))
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color("UserInputBackground"))
                            .padding(15)
                    )
                HStack {
                    Spacer()
                    Button(
                        action: {
                            Task {
                                await model.submit()
                            }
                        },
                        label: {
                            Image(systemName: "paperplane")
                        }
                    )
                    .frame(width: 30, height: 30)
                    .disabled(!model.canSubmit)
                }
                .padding(.bottom, 20)
                .padding(.trailing, 30)
            }
            .frame(maxHeight: 90)
        }
    }
}

struct PromptAndResponsesView: View {
    @Binding var promptResponses: [PromptResponse]

    var body: some View {
        ScrollView {
            ForEach(promptResponses) { promptResponse in
                Text(promptResponse.prompt)
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                    .background(Color("UserInputBackground"))
                Text(promptResponse.response)
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
            }
        }
    }
}

struct ChatView_Previews: PreviewProvider {
    static var previews: some View {
        ChatView(model: ChatModel(promptSender: FakePromptSender()))
    }
}

extension NSTextView {
    open override var frame: CGRect {
        didSet {
            backgroundColor = .clear
            drawsBackground = true
        }
    }
}
