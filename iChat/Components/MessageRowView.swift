//
//  MessageRowView.swift
//  iChat
//
//  Created by Mehran Khani on 11.08.2024.
//

import SwiftUI

struct MessageRowView: View {
    @Environment (\.colorScheme) private var colorScheme
    let message: MessageRow
    let retryCallBack: (MessageRow) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            messageRow(
                text: message.sendText,
                image: message.sendImage,
                bgColor: colorScheme == .light ? .white
            : Color(red: 52/255, green: 53/255, blue: 65/255, opacity: 0.5))
            
            
            if let response = message.responseText {
                Divider()
                messageRow(
                    text: response,
                    image: message.responseImage,
                    bgColor: colorScheme == .light ? .gray.opacity(0.1)
                    : Color(red: 52/255, green: 53/255, blue: 65/255, opacity: 1),
                    responseError: message.responseError,
                    showDotLoading: message.isInteractingWithChatGPT)
                Divider()
            }
            
        }
    }
    
    func messageRow(
        text: String,
        image: String,
        bgColor: Color,
        responseError: String? = nil,
        showDotLoading: Bool = false) -> some View {
            
        HStack(alignment: .top, spacing: 24) {
            
            if image.hasPrefix("http"), let url = URL(string: image) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .frame(width: 25, height: 25)
                } placeholder: {
                    ProgressView()
                }
            } else {
                Image(image)
                    .resizable()
                    .frame(width: 25, height: 25)
            }
            
            VStack(alignment: .leading) {
                
                if !text.isEmpty {
                    Text(text)
                        .multilineTextAlignment(.leading)
                        .textSelection(.enabled)
                }
                
                if let error = responseError {
                    Text("An error has occured: \(error)")
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.leading)
                        
                    Button("Regenrate Response") {
                        retryCallBack(message)
                    }
                    .foregroundStyle(Color.accentColor)
                    .padding(.top)
                }
                
                if showDotLoading {
                    LoadingDots()
                        .frame(width: 60, height: 30)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(bgColor)
    }
}

struct MessageRowView_Previews: PreviewProvider {
    
    static let message1 = MessageRow(
        isInteractingWithChatGPT: true,
        sendImage: "openai",
        sendText: "what is swiftui?",
        responseImage: "openai",
        responseText: "swift ui is a user interface framework that allows developers ...") 
    
    static let message2 = MessageRow(
        isInteractingWithChatGPT: false,
        sendImage: "openai",
        sendText: "what is swiftui?",
        responseImage: "openai",
        responseText: "",
        responseError: "ChatGPT is currently not available")
    
    static var previews: some View {
        NavigationStack {
            ScrollView {
                MessageRowView(message: message1, retryCallBack: { messageRow in
                })
                .frame(width: 400)
                .previewLayout(.sizeThatFits)  
                
                MessageRowView(message: message2, retryCallBack: { messageRow in
                })
                .frame(width: 400)
                .previewLayout(.sizeThatFits)
            }
        }
    }
}
