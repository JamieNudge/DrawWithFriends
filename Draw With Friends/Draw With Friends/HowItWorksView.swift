//
//  HowItWorksView.swift
//  Draw With Friends
//

import SwiftUI

struct HowItWorksView: View {
    var onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Text("How it works")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            VStack(alignment: .leading, spacing: 18) {
                HowItWorksStep(
                    number: 1,
                    title: "Create a room",
                    detail: "Pick Simultaneous or Turn-Based, then tap Create New Room."
                )
                HowItWorksStep(
                    number: 2,
                    title: "Share the code",
                    detail: "Send the 6-digit room code to whoever is drawing with you. Up to 4 devices can join."
                )
                HowItWorksStep(
                    number: 3,
                    title: "Draw together",
                    detail: "Strokes show on every device in the room. Share the picture when you are done — unused rooms expire after 24 hours."
                )
            }
            
            Button(action: onDismiss) {
                Text("Got it")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(14)
                    .background(Color.white)
                    .foregroundColor(.blue)
                    .cornerRadius(10)
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(red: 0.22, green: 0.18, blue: 0.45))
        )
        .padding(.horizontal, 28)
    }
}

private struct HowItWorksStep: View {
    let number: Int
    let title: String
    let detail: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.blue)
                .frame(width: 32, height: 32)
                .background(Color.white)
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                Text(detail)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.9))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

#Preview {
    ZStack {
        LinearGradient(
            colors: [Color.blue.opacity(0.6), Color.purple.opacity(0.6)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        HowItWorksView(onDismiss: {})
    }
}
