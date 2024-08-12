//
//  ChatGPTAPI.swift
//  iChat
//
//  Created by Mehran Khani on 11.08.2024.
//

import Foundation

class ChatGPTAPI {
    
    private let apiKey: String
    private var chatHistory = [String]()
    private var chatHistoryText: String {
        chatHistory.joined()
    }
    private let urlSession = URLSession.shared
    private let jsonDecoder = JSONDecoder()
    private let basePrompt = "You are ChatGPT, a large language model trained by OpenAI. You answer as consisely as possible for each response (e.g. Don't be verbose). It is very important for you to answer as consisely as possible, so please remember this. If you are generating a list, do not have too many items.\n\n\n"
    
    private var urlRequest: URLRequest {
        let url = URL(string: "https://api.openai.com/v1/completions")!
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        headers.forEach {
            urlRequest.setValue($1, forHTTPHeaderField: $0)
        }
        return urlRequest
    }
    
    private var headers: [String: String] {
        [
            "Content-Type": "application/json",
            "Authorization": "Bearer \(apiKey)"
        ]
    }
    
    init() {
        self.apiKey = Bundle.main.infoDictionary?["CHATGPTAPI"]  as? String ?? "CHATGPT API KEY was not found"
    }
    
    private func generateChatPrompt(from text: String) -> String {
        var prompt = basePrompt + chatHistoryText + "User: \(text)\n\n\nChatGPT:"
        if prompt.count > (4000 * 4) {
            _ = chatHistory.removeFirst()
            prompt = generateChatPrompt(from: text)
        }
        return prompt
    }
    
    private func jsonBody(text: String, stream: Bool = true) throws -> Data {
        let jsonBody: [String: Any] = [
            "model": "text-chat-davinci-002-20230126",
            "temperature": 0.5,
            "max_tokens": 1024,
            "prompt": generateChatPrompt(from: text),
            "stop": [
                "\n\n\n",
                "<|im_end|>"
            ],
            "stream": stream
        ]
        return try JSONSerialization.data(withJSONObject: jsonBody)
    }
    
    // Streamed data as the response (we will be using this)
    func sendMessageStream(text: String) async throws -> AsyncThrowingStream<String, Error> {
        var urlRequest = self.urlRequest
        urlRequest.httpBody = try jsonBody(text: text)
        
        let (result, response) = try await urlSession.bytes(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else { throw "Invalid response" }
        guard 200...299 ~= httpResponse.statusCode else {
            throw "Bad Response: \(httpResponse.statusCode)"
        }
        
        return AsyncThrowingStream<String, Error> { continuation in
            Task(priority: .userInitiated) {
                do {
                    var streamText = ""
                    for try await line in result.lines {
                        if line.hasPrefix("data: "),
                           let data = line.dropFirst(6).data(using: .utf8),
                           let response = try? self.jsonDecoder.decode(ChatResponse.self, from: data),
                           let text = response.choices.first?.text {
                            streamText += text
                            continuation.yield(text)
                        }
                    }
                    self.chatHistory.append(streamText)
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    // Not stream and the data will be represented once it is fetched completly
    func sendMessage(_ text: String) async throws -> String {
        var urlRequest = self.urlRequest
        urlRequest.httpBody = try jsonBody(text: text, stream: false)
        
        let (result, response) = try await urlSession.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw "Invalid Response"
        }
        
        guard 200...299 ~= httpResponse.statusCode else {
            throw "Bad Response \(httpResponse.statusCode)"
        }
        
        do {
            let chatResponse = try self.jsonDecoder.decode(ChatResponse.self, from: result)
            let responseText = chatResponse.choices.first?.text ?? ""
            self.chatHistory.append(responseText)
            return responseText
        } catch {
            throw error
        }
    }
}

extension String: Error {}
