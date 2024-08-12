//
//  ContentView.swift
//  iChat
//
//  Created by Mehran Khani on 7.08.2024.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    let api = ChatGPTAPI()
    
    var body: some View {
        VStack {
            Group {
                if authViewModel.userSession != nil {
                    HomeView()
                } else {
                    LoginView()
                }
                
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthViewModel())
}
