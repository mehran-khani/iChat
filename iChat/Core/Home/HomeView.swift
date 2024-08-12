//
//  HomeView.swift
//  iChat
//
//  Created by Mehran Khani on 12.08.2024.
//

import SwiftUI

struct HomeView: View {
    @Environment (\.colorScheme) var colorScheme
    @StateObject var viewModel = HomeViewModel(api: ChatGPTAPI())
    @EnvironmentObject var authViewModel: AuthViewModel
    @FocusState var isTextFieldFocused: Bool

    var body: some View {
            chatListView
                .navigationTitle("iChat")
    }
    
    var chatListView : some View {
        ScrollViewReader { proxy in
            VStack(spacing: 0) {
                ScrollView{
                    LazyVStack(spacing: 0) {
                        ForEach(viewModel.messages) { message in
                            MessageRowView(message: message) { message in
                                Task { @MainActor in
                                    await viewModel.retry(message:message)
                                }
                            }
                        }
                    }
                    .onTapGesture {
                        isTextFieldFocused = false
                    }
                }
                Divider()
                bottomView(image: nil, proxy: proxy)
                Spacer()
            }
            .onChange(of: viewModel.messages.last?.responseText) {
                scrollToBottom(proxy: proxy)
            }
        }
        .background(colorScheme == .light ? .white
                    :Color(red: 52/255, green: 53/255, blue: 65/255, opacity: 0.5))
    }
    
    func bottomView(image: String?, proxy: ScrollViewProxy) -> some View {
        HStack(alignment: .center, spacing: 8) {
            if let imageURLString = image,
               let url = URL(string: imageURLString),
               imageURLString.hasPrefix("http") {
                // Load and display image from URL
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .frame(width: 30, height: 30)
                } placeholder: {
                    ProgressView()
                }
            } else if let imageName = image {
                // Display local image if the image name is valid
                Image(imageName)
                    .resizable()
                    .frame(width: 30, height: 30)
            } else {
                // Display initials if no valid image URL or name is provided
                Text(authViewModel.currentUser?.initials ?? "u")
                    .font(.title)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .frame(width: 30, height: 30)
                    .background(Color(.systemGray3))
                    .clipShape(Circle())
            }
            
            TextField("Send message", text: $viewModel.inputMessage, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .focused($isTextFieldFocused)
                .disabled(viewModel.isInteractingWithChatGPT)
            
            if viewModel.isInteractingWithChatGPT {
                LoadingDots().frame(width: 60, height: 30)
            } else {
                Button {
                    Task { @MainActor in
                        isTextFieldFocused = false
                        scrollToBottom(proxy: proxy)
                        await viewModel.sendTapped()
                    }
                } label: {
                    Image(systemName: "paperplane.circle.fill")
                        .rotationEffect(.degrees(45))
                        .font(.system(size: 30))
                }
                .disabled(viewModel.inputMessage.trimmingCharacters(in:
                        .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }
    
    private func scrollToBottom (proxy: ScrollViewProxy) {
        guard let id = viewModel.messages.last?.id else { return }
        proxy.scrollTo(id, anchor: .bottomTrailing)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            HomeView()
        }
    }
}
