//
//  ContentView.swift
//  Draw With Friends
//
//  Created by Jamie on 09/11/2025.
//

import SwiftUI

struct ContentView: View {
    @State private var isInRoom = false
    @State private var currentRoomCode: String? = nil
    
    var body: some View {
        ZStack {
            if isInRoom && currentRoomCode != nil {
                DrawingCanvasView()
                    .transition(.move(edge: .trailing))
                    .onAppear {
                        // Start observing room code changes only when in room
                        observeRoomCode()
                    }
            } else {
                RoomView(onRoomJoined: {
                    withAnimation {
                        isInRoom = true
                        currentRoomCode = FirebaseManager.shared.currentRoomCode
                    }
                })
                .transition(.move(edge: .leading))
            }
        }
    }
    
    private func observeRoomCode() {
        // Check periodically if room code changes (e.g., if user leaves room)
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { timer in
            let roomCode = FirebaseManager.shared.currentRoomCode
            if roomCode != currentRoomCode {
                currentRoomCode = roomCode
                if roomCode == nil {
                    withAnimation {
                        isInRoom = false
                    }
                    timer.invalidate()
                }
            }
            if !isInRoom {
                timer.invalidate()
            }
        }
    }
}

#Preview {
    ContentView()
}
