//
//  ContentView.swift
//  Draw With Friends
//
//  Created by Jamie on 09/11/2025.
//

import SwiftUI
import UIKit

enum CanvasOrientationLock {
    static var allowed: UIInterfaceOrientationMask = .all
    
    static func lockToCurrentOrientation() {
        switch foregroundScene()?.interfaceOrientation {
        case .landscapeLeft, .landscapeRight:
            allowed = .landscape
        default:
            allowed = .portrait
        }
        apply()
    }
    
    static func unlock() {
        allowed = .all
        apply()
    }
    
    static func apply() {
        for scene in UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }) {
            scene.requestGeometryUpdate(.iOS(interfaceOrientations: allowed)) { _ in }
            let root = scene.keyWindow?.rootViewController ?? scene.windows.first?.rootViewController
            root?.setNeedsUpdateOfSupportedInterfaceOrientations()
        }
    }
    
    private static func foregroundScene() -> UIWindowScene? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        return scenes.first { $0.activationState == .foregroundActive } ?? scenes.first
    }
}

/// SwiftUI's hosting controller reports every orientation. This child VC
/// refreshes the lock once it has a window, which AppDelegate alone did not.
final class CanvasOrientationLockController: UIViewController {
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        CanvasOrientationLock.allowed
    }
    
    override var shouldAutorotate: Bool { true }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = false
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        CanvasOrientationLock.apply()
    }
}

struct CanvasOrientationLockProbe: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> CanvasOrientationLockController {
        CanvasOrientationLockController()
    }
    
    func updateUIViewController(_ uiViewController: CanvasOrientationLockController, context: Context) {}
}

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
                    CanvasOrientationLock.lockToCurrentOrientation()
                    withAnimation {
                        isInRoom = true
                        currentRoomCode = FirebaseManager.shared.currentRoomCode
                    }
                })
                .transition(.move(edge: .leading))
            }
        }
        .onChange(of: isInRoom) { inRoom in
            if !inRoom {
                CanvasOrientationLock.unlock()
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
