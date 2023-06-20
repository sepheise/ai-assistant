//
//  PromptTextInputView.swift
//  AIAssistantMacOSApp
//
//  Created by Patricio Sepúlveda Heise on 20-06-23.
//

import SwiftUI

struct PromptTextInputView: View {
    @Binding var inputText: String
    @Binding var canSubmit: Bool
    let submit: () async -> Void

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            TextEditor(text: $inputText)
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
                            await submit()
                        }
                    },
                    label: {
                        Image(systemName: "paperplane")
                    }
                )
                .frame(width: 30, height: 30)
                .disabled(!canSubmit)
            }
            .padding(.bottom, 20)
            .padding(.trailing, 30)
        }
        .frame(maxHeight: 90)
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
