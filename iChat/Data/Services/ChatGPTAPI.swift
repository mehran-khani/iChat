//
//  ChatGPTAPI.swift
//  iChat
//
//  Created by Mehran Khani on 11.08.2024.
//

import Foundation

class ChatGPTAPI {
    
    private let systemMessage: Message
    private let temperature: Double
    private let model: String
    private let apiKey: String
    private var chatHistory = [Message]()

    private let urlSession = URLSession.shared
    private let jsonDecoder: JSONDecoder = {
        let jsonDecoder = JSONDecoder()
        jsonDecoder.keyDecodingStrategy = .convertFromSnakeCase
        return jsonDecoder
    }()
    
    private var urlRequest: URLRequest {
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        headers.forEach {
            urlRequest.setValue($1, forHTTPHeaderField: $0)
        }
        return urlRequest
    }
    
    let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "YYYY-MM-DD"
        return formatter
    }()
    
    private var headers: [String: String] {
        [
            "Content-Type": "application/json",
            "Authorization": "Bearer \(apiKey)"
        ]
    }
    
    init(model: String = "gpt-3.5-turbo", systemPrompt: String = "You are a helpful assistant", temperature: Double = 0.5) {
        self.apiKey = Bundle.main.infoDictionary?["CHATGPTAPI"] as! String
        self.model = model
        self.systemMessage = .init(role: "system", content: systemPrompt)
        self.temperature = temperature
    }
    
    private func generateMessages(from text: String) -> [Message] {
        var message = [systemMessage] + chatHistory + [Message(role: "user", content: text)]
        if message.count > (4000 * 4) {
            _ = chatHistory.removeFirst()
            message = generateMessages(from: text)
        }
        return message
    }
    
    private func jsonBody(text: String, stream: Bool = true) throws -> Data {
        let request = Request(
            model: model,
            temperature: temperature,
            messages: generateMessages(from: text),
            stream: stream)
        
        return try JSONEncoder().encode(request)
    }
    
    private func appendToChatHistory(userText: String, responseText: String) {
        self.chatHistory.append(.init(role: "user", content: userText))
        self.chatHistory.append(.init(role: "assistant", content: responseText))
    }
    
    // Streamed data as the response (we will be using this)
    func sendMessageStream(text: String) async throws -> AsyncThrowingStream<String, Error> {
        var urlRequest = self.urlRequest
        urlRequest.httpBody = try jsonBody(text: text)
        
        let (result, response) = try await urlSession.bytes(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else { throw "Invalid response" }
        guard 200...299 ~= httpResponse.statusCode else {
            var error = ""
            for try await line in result.lines {
                error += line
            }
            if let errorData = error.data(using: .utf8),
               let errorRespone = try? jsonDecoder.decode(ErrorRootResponse.self, from: errorData).error {
                error = "\n\(errorRespone.message)"
            }
            throw "Bad Response: \(httpResponse.statusCode), \(error)"
        }
        
        return AsyncThrowingStream<String, Error> { continuation in
            Task(priority: .userInitiated) { [weak self] in
                guard let self else { return }
                do {
                    var responseText = ""
                    for try await line in result.lines {
                        if line.hasPrefix("data: "),
                           let data = line.dropFirst(6).data(using: .utf8),
                           let response = try? self.jsonDecoder.decode(StreamCompletionResponse.self, from: data),
                           let text = response.choices.first?.delta.content {
                            responseText += text
                            continuation.yield(text)
                        }
                    }
                    self.appendToChatHistory(userText: text, responseText: responseText)
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
            var error = "Bad Response: \(httpResponse.statusCode)"
            if let errorRootResponse = try? jsonDecoder.decode(ErrorRootResponse.self, from: result).error {
                error.append("\n\(errorRootResponse.message)")
            }
            throw error
        }
        
        do {
            let completionResonse = try self.jsonDecoder.decode(CompletionResponse.self, from: result)
            let responseText = completionResonse.choices.first?.message.content ?? ""
            self.appendToChatHistory(userText: text, responseText: responseText)
            return responseText
        } catch {
            throw error
        }
    }
    
    func deleteChatHistory() {
        self.chatHistory.removeAll()
    }
}

extension String: Error {}
