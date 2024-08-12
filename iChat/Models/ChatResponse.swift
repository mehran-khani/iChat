//
//  ChatResponse.swift
//  iChat
//
//  Created by Mehran Khani on 11.08.2024.
//

import Foundation

struct ChatResponse: Decodable {
    let choices: [Choice]
}

struct Choice: Decodable {
    let text: String
}
