//
//  HomeViewModel.swift
//  iChat
//
//  Created by Mehran Khani on 11.08.2024.
//
import Foundation
import SwiftUI

@MainActor
class HomeViewModel: ObservableObject {
    @Published var isInteractingWithChatGPT: Bool = false
    @Published var messages: [MessageRow] = []
    @Published var inputMessage: String = ""
    
    private let api: ChatGPTAPI
    
    init(api: ChatGPTAPI) {
        self.api = api
    }
    
    @MainActor
    func sendTapped() async {
        let text = inputMessage
        inputMessage = ""
        await send(text: text)
    }
    
    @MainActor
    func clearMessages() {
        self.api.deleteChatHistory()
        withAnimation { [weak self] in
            self?.messages = []
        }
    }
    
    @MainActor
    func retry(message: MessageRow) async {
        guard let index = messages.firstIndex(where: { $0.id == message.id }) else { return }
        self.messages.remove(at: index)
        await send(text: message.sendText)
        
    }
    
    @MainActor
    private func send(text: String) async {
        isInteractingWithChatGPT = true
        var streamText = ""
        var messageRow = MessageRow(
            isInteractingWithChatGPT: true,
            sendImage: "openai",
            sendText: text,
            responseImage: "openai",
            responseText: streamText,
            responseError: nil)
        
        self.messages.append(messageRow)
        
        do {
            let stream = try await api.sendMessageStream(text: text)
            for try await text in stream {
                streamText += text
                messageRow.responseText = streamText.trimmingCharacters(in: .whitespacesAndNewlines)
                self.messages[self.messages.count - 1] = messageRow
            }
        } catch {
            messageRow.responseError = error.localizedDescription
        }
        messageRow.isInteractingWithChatGPT = false
        self.messages[self.messages.count - 1] = messageRow
        isInteractingWithChatGPT = false
    }
}
