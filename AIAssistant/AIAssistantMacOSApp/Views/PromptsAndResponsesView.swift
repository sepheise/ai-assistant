//
//  PromptAndResponsesView.swift
//  AIAssistantMacOSApp
//
//  Created by Patricio Sepúlveda Heise on 20-06-23.
//

import SwiftUI
import AIAssistant

struct PromptsAndResponsesView: View {
    @Binding var promptResponses: [PromptResponse]

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                ForEach(promptResponses, id: \.id) { promptResponse in
                    Text(promptResponse.prompt)
                        .textSelection(.enabled)
                        .padding(20)
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                        .background(Color("UserInputBackground"))
                    Text(LocalizedStringKey(promptResponse.response))
                        .textSelection(.enabled)
                        .padding(20)
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                        .id(promptResponse.id)
                }
            }
            .onAppear {
                withAnimation {
                    proxy.scrollTo(promptResponses.last?.id, anchor: .bottom)
                }
            }
            .onChange(of: promptResponses) { _ in
                withAnimation {
                    proxy.scrollTo(promptResponses.last?.id, anchor: .bottom)
                }
            }
        }
    }
}

struct PromptsAndResponsesView_Previews: PreviewProvider {
    static let previewPromptResponses = [
        PromptResponse(id: 0, prompt: "Question 1", response: "Some answer to question 1"),
        PromptResponse(id: 1, prompt: "Question 2", response: "Some answer to question 2"),
        PromptResponse(id: 2, prompt: "Question 3", response: "Some answer to question 3")
    ]

    static var previews: some View {
        PromptsAndResponsesView(promptResponses: .constant(previewPromptResponses))
    }
}
