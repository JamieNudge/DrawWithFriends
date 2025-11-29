//
//  RoomView.swift
//  Draw With Friends
//
//  Created by Jamie on 09/11/2025.
//

import SwiftUI

struct RoomView: View {
    // Don't initialize FirebaseManager until actually needed (lazy access)
    @State private var roomCode = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isJoiningRoom = false
    @State private var selectedMode: RoomMode = .simultaneous
    @FocusState private var isRoomCodeFocused: Bool
    
    var onRoomJoined: () -> Void
    
    enum RoomMode {
        case turnBased
        case simultaneous
    }
    
    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                colors: [Color.blue.opacity(0.6), Color.purple.opacity(0.6)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 15) {
                // Title - shrink when keyboard appears
                VStack(spacing: 8) {
                    Image("AppIconImage")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: isRoomCodeFocused ? 60 : 100, height: isRoomCodeFocused ? 60 : 100)
                        .cornerRadius(20)
                        .shadow(radius: 5)
                    
                    if !isRoomCodeFocused {
                        Text("Draw With Friends")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("Collaborate in real-time!")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.9))
                    }
                }
                .padding(.top, isRoomCodeFocused ? 10 : 30)
                
                // Room controls
                VStack(spacing: 12) {
                    // Mode selector
                    VStack(spacing: 8) {
                        Text("Choose Drawing Mode")
                            .foregroundColor(.white)
                            .fontWeight(.bold)
                            .font(.headline)
                        
                        HStack(spacing: 15) {
                            // Simultaneous Mode Button
                            Button(action: {
                                selectedMode = .simultaneous
                            }) {
                                VStack(spacing: 4) {
                                    Image(systemName: "bolt.fill")
                                        .font(.system(size: 24))
                                    Text("Simultaneous")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                }
                                .foregroundColor(selectedMode == .simultaneous ? .white : .white.opacity(0.6))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .padding(.horizontal, 8)
                                .background(selectedMode == .simultaneous ? Color.green : Color.white.opacity(0.2))
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.white, lineWidth: selectedMode == .simultaneous ? 2 : 0)
                                )
                            }
                            
                            // Turn-Based Mode Button
                            Button(action: {
                                selectedMode = .turnBased
                            }) {
                                VStack(spacing: 4) {
                                    Image(systemName: "person.2.fill")
                                        .font(.system(size: 24))
                                    Text("Turn-Based")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                }
                                .foregroundColor(selectedMode == .turnBased ? .white : .white.opacity(0.6))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .padding(.horizontal, 8)
                                .background(selectedMode == .turnBased ? Color.blue : Color.white.opacity(0.2))
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.white, lineWidth: selectedMode == .turnBased ? 2 : 0)
                                )
                            }
                        }
                    }
                    .padding()
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(15)
                    
                    // Create new room button
                    Button(action: createRoom) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Create New Room")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(12)
                        .background(Color.white)
                        .foregroundColor(.blue)
                        .cornerRadius(10)
                    }
                    
                    // Divider
                    HStack {
                        Rectangle()
                            .fill(Color.white.opacity(0.5))
                            .frame(height: 1)
                        Text("OR")
                            .foregroundColor(.white)
                            .fontWeight(.semibold)
                        Rectangle()
                            .fill(Color.white.opacity(0.5))
                            .frame(height: 1)
                    }
                    
                    // Join existing room - isolated to prevent parent re-renders
                    RoomCodeInputView(
                        roomCode: $roomCode,
                        isRoomCodeFocused: $isRoomCodeFocused,
                        onJoinRoom: joinRoom
                    )
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 10)
                
                Spacer(minLength: 0)
            }
            .animation(.easeInOut(duration: 0.3), value: isRoomCodeFocused)
            
            // Tap anywhere to dismiss keyboard
            if isRoomCodeFocused {
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        isRoomCodeFocused = false
                    }
                    .ignoresSafeArea()
            }
        }
        .alert("Room Status", isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        .overlay {
            if isJoiningRoom {
                ZStack {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                    
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.white)
                }
            }
        }
    }
    
    private func createRoom() {
        isJoiningRoom = true
        
        let isTurnBased = (selectedMode == .turnBased)
        // Access FirebaseManager only when actually needed (lazy initialization)
        FirebaseManager.shared.createRoom(isTurnBased: isTurnBased, creatorId: UserSession.shared.userId) { roomCode in
            isJoiningRoom = false
            
            if let code = roomCode {
                let modeText = isTurnBased ? "Turn-Based" : "Simultaneous"
                alertMessage = "Room created! (\(modeText))\nShare code: \(code)"
                showAlert = true
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    onRoomJoined()
                }
            } else {
                alertMessage = "Failed to create room. Please try again."
                showAlert = true
            }
        }
    }
    
    private func joinRoom() {
        guard !roomCode.isEmpty else { return }
        
        isJoiningRoom = true
        
        // Access FirebaseManager only when actually needed (lazy initialization)
        FirebaseManager.shared.joinRoom(code: roomCode) { success in
            isJoiningRoom = false
            
            if success {
                onRoomJoined()
            } else {
                alertMessage = "Room not found. Please check the code and try again."
                showAlert = true
            }
        }
    }
}

// Isolated TextField component to prevent parent view re-renders
struct RoomCodeInputView: View {
    @Binding var roomCode: String
    @FocusState.Binding var isRoomCodeFocused: Bool
    let onJoinRoom: () -> Void
    
    var body: some View {
        VStack(spacing: 10) {
            ZStack(alignment: .trailing) {
                ZStack {
                    // Custom placeholder
                    if roomCode.isEmpty {
                        Text("Enter Room Code")
                            .foregroundColor(.gray)
                            .font(.title3)
                    }
                    
                    TextField("", text: $roomCode)
                        .keyboardType(.numberPad)
                        .font(.title3)
                        .foregroundColor(.black)
                        .multilineTextAlignment(.center)
                        .focused($isRoomCodeFocused)
                        .autocorrectionDisabled(true)
                        .textInputAutocapitalization(.never)
                        .accentColor(.purple)
                }
                .padding(12)
                .padding(.trailing, 40) // Space for clear button
                .background(Color.white)
                .cornerRadius(10)
                
                // Clear button overlaid on the right
                Button(action: {
                    roomCode = ""
                    isRoomCodeFocused = true
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray.opacity(0.7))
                        .font(.title2)
                        .padding(.trailing, 12)
                }
                .opacity(roomCode.isEmpty ? 0 : 1)
                .disabled(roomCode.isEmpty)
            }
            
            Button(action: {
                isRoomCodeFocused = false
                onJoinRoom()
            }) {
                HStack {
                    Image(systemName: "arrow.right.circle.fill")
                    Text("Join Room")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.white)
                .foregroundColor(.purple)
                .cornerRadius(10)
            }
            .disabled(roomCode.isEmpty)
            .opacity(roomCode.isEmpty ? 0.5 : 1)
        }
    }
}

#Preview {
    RoomView(onRoomJoined: {})
}


