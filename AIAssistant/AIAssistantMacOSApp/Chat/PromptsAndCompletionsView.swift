//
//  PromptsAndCompletionsView.swift
//  AIAssistantMacOSApp
//
//  Created by Patricio Sepúlveda Heise on 20-06-23.
//

import SwiftUI
import AIAssistant

struct PromptsAndCompletionsView: View {
    @Binding var prompts: [Prompt]

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                ForEach(prompts, id: \.id) { prompt in
                    Text(prompt.content)
                        .textSelection(.enabled)
                        .padding(20)
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                        .background(Color("UserInputBackground"))

                    MarkdownTest(text: prompt.completion?.content ?? "")
                        .textSelection(.enabled)
                        .padding(20)
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                        .id(prompt.id)
                }
            }
            .onAppear {
                withAnimation {
                    proxy.scrollTo(prompts.last?.id, anchor: .bottom)
                }
            }
            .onChange(of: prompts) { _ in
                withAnimation {
                    proxy.scrollTo(prompts.last?.id, anchor: .bottom)
                }
            }
        }
    }
}

struct MarkdownTest: View {
    let text: String

    var body: some View {
        Text(try! AttributedString(markdown: text))
    }
}

struct PromptsAndResponsesView_Previews: PreviewProvider {
    static let previewPrompts = [
        Prompt(id: UUID(), "Question 1", completion: Completion("Some answer to question 1")),
        Prompt(id: UUID(), "Question 2", completion: Completion("Some answer to question 2")),
        Prompt(id: UUID(), "Question 3", completion: Completion("Some answer to question 3"))
    ]

    static var previews: some View {
        PromptsAndCompletionsView(prompts: .constant(previewPrompts))
    }
}
