//
//  ChatView.swift
//  AIAssistantMacOSApp
//
//  Created by Patricio Sepúlveda Heise on 17-06-23.
//

import SwiftUI
import AIAssistant

struct ChatView: View {
    @ObservedObject private var store: ChatStore

    init(store: ChatStore) {
        self.store = store
    }

    var body: some View {
        VStack(alignment: .leading) {
            Text(store.responseText)
            Spacer()
            ZStack(alignment: .bottomTrailing) {
                TextEditor(text: $store.inputText)
                    .font(.body)
                    .padding(EdgeInsets(top: 21, leading: 20, bottom: 19, trailing: 15))
                    .background(                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color("UserInputBackground"))
                        .padding(15)
                    )
                HStack {
                    Spacer()
                    Button(
                        action: { store.submit() },
                        label: {
                            Image(systemName: "paperplane")
                        }
                    )
                    .frame(width: 30, height: 30)
                    .disabled(!store.canSubmit)
                }
                .padding(.bottom, 20)
                .padding(.trailing, 30)
            }
            .frame(maxHeight: 90)
        }
    }
}

struct ChatView_Previews: PreviewProvider {
    static var previews: some View {
        ChatView(store: ChatStore(promptSender: FakePromptSender()))
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
