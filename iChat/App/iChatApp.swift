//
//  iChatApp.swift
//  iChat
//
//  Created by Mehran Khani on 7.08.2024.
//

import SwiftUI
import SwiftData
import Firebase
@main
struct iChatApp: App {
    @StateObject var authViewModel = AuthViewModel()
    @StateObject var homeViewModel = HomeViewModel(api: ChatGPTAPI())
    
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                ContentView()
                    .toolbar {
                        ToolbarItem {
                            Button() {
                                homeViewModel.clearMessages()
                            } label: {
                                Image(systemName: "trash")
                            }
                            .disabled(homeViewModel.isInteractingWithChatGPT)
                        }
                    }
                    .environmentObject(authViewModel)
            }
        }
    }
}
