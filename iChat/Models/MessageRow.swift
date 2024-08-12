//
//  MessageRow.swift
//  iChat
//
//  Created by Mehran Khani on 11.08.2024.
//

import Foundation

struct MessageRow: Identifiable {
    let id = UUID()
    var isInteractingWithChatGPT: Bool
    
    let sendImage: String
    let sendText: String
    
    let responseImage: String
    var responseText: String?
    
    var responseError: String?
}
