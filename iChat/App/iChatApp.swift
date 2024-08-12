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
    
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                ContentView()
                    .environmentObject(authViewModel)
            }
        }
    }
}
