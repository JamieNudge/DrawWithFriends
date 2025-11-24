//
//  FirebaseManager.swift
//  Draw With Friends
//
//  Created by Jamie on 09/11/2025.
//

import Foundation
import Combine
import CoreGraphics
import FirebaseCore
import FirebaseDatabase

class FirebaseManager: ObservableObject {
    static let shared = FirebaseManager()
    private var database: DatabaseReference
    
    @Published var isConnected = false
    @Published var currentRoomCode: String?
    
    private init() {
        // Firebase is already configured in AppDelegate
        database = Database.database().reference()
        
        // Monitor connection status - must be on main thread
        let connectedRef = Database.database().reference(withPath: ".info/connected")
        connectedRef.observe(.value) { [weak self] snapshot in
            DispatchQueue.main.async {
                if let connected = snapshot.value as? Bool {
                    self?.isConnected = connected
                }
            }
        }
    }
    
    // MARK: - Room Management
    
    func createRoom(isTurnBased: Bool, creatorId: String, completion: @escaping (String?) -> Void) {
        // Generate a random 6-digit room code
        let roomCode = String(format: "%06d", Int.random(in: 0...999999))
        
        let roomRef = database.child("rooms").child(roomCode)
        
        // Create room with metadata
        var roomData: [String: Any] = [
            "createdAt": ServerValue.timestamp(),
            "isActive": true,
            "mode": isTurnBased ? "turnBased" : "simultaneous"
        ]
        
        // For turn-based, set initial turn to creator
        if isTurnBased {
            roomData["currentTurn"] = creatorId
            roomData["turnStartTime"] = ServerValue.timestamp()
        }
        
        roomRef.setValue(roomData) { error, _ in
            if error == nil {
                self.currentRoomCode = roomCode
                completion(roomCode)
            } else {
                completion(nil)
            }
        }
    }
    
    func getRoomMode(completion: @escaping (String?) -> Void) {
        guard let roomCode = currentRoomCode else {
            completion(nil)
            return
        }
        
        let roomRef = database.child("rooms").child(roomCode)
        roomRef.observeSingleEvent(of: .value) { snapshot in
            if let data = snapshot.value as? [String: Any],
               let mode = data["mode"] as? String {
                completion(mode)
            } else {
                completion(nil)
            }
        }
    }
    
    // MARK: - Turn Management
    
    func observeCurrentTurn(completion: @escaping (String?) -> Void) {
        guard let roomCode = currentRoomCode else { return }
        
        let turnRef = database.child("rooms").child(roomCode).child("currentTurn")
        turnRef.observe(.value) { snapshot in
            completion(snapshot.value as? String)
        }
    }
    
    func passTurn(toUserId: String) {
        guard let roomCode = currentRoomCode else { return }
        
        let roomRef = database.child("rooms").child(roomCode)
        roomRef.updateChildValues([
            "currentTurn": toUserId,
            "turnStartTime": ServerValue.timestamp()
        ])
    }
    
    func getUsersInRoom(completion: @escaping ([String]) -> Void) {
        guard let roomCode = currentRoomCode else {
            completion([])
            return
        }
        
        // Get all users who have drawn in the room
        let usersRef = database.child("rooms").child(roomCode).child("users")
        usersRef.observeSingleEvent(of: .value) { snapshot in
            if let usersData = snapshot.value as? [String: Any] {
                let userIds = Array(usersData.keys)
                completion(userIds)
            } else {
                completion([])
            }
        }
    }
    
    func registerUserInRoom(userId: String) {
        guard let roomCode = currentRoomCode else { return }
        
        let userRef = database.child("rooms").child(roomCode).child("users").child(userId)
        userRef.setValue([
            "joinedAt": ServerValue.timestamp(),
            "isActive": true
        ])
    }
    
    func joinRoom(code: String, completion: @escaping (Bool) -> Void) {
        let roomRef = database.child("rooms").child(code)
        
        // Check if room exists
        roomRef.observeSingleEvent(of: .value) { snapshot in
            if snapshot.exists() {
                self.currentRoomCode = code
                completion(true)
            } else {
                completion(false)
            }
        }
    }
    
    // MARK: - Drawing Data Sync (Turn-Based Mode)
    
    func sendDrawing(_ drawingData: Data, userId: String, canvasSize: CGSize, drawingBounds: CGRect) {
        guard let roomCode = currentRoomCode else { return }
        
        let drawingRef = database.child("rooms").child(roomCode).child("sharedDrawing")
        
        let data: [String: Any] = [
            "data": drawingData.base64EncodedString(),
            "timestamp": ServerValue.timestamp(),
            "lastEditedBy": userId,
            "canvasWidth": canvasSize.width,
            "canvasHeight": canvasSize.height,
            "boundsX": drawingBounds.origin.x,
            "boundsY": drawingBounds.origin.y,
            "boundsWidth": drawingBounds.width,
            "boundsHeight": drawingBounds.height
        ]
        
        drawingRef.setValue(data)
    }
    
    func observeSharedDrawing(completion: @escaping (Data?, String?, CGSize?, CGRect?) -> Void) {
        guard let roomCode = currentRoomCode else { return }
        
        let drawingRef = database.child("rooms").child(roomCode).child("sharedDrawing")
        
        drawingRef.observe(.value) { snapshot in
            if let data = snapshot.value as? [String: Any],
               let base64String = data["data"] as? String,
               let drawingData = Data(base64Encoded: base64String) {
                let lastEditor = data["lastEditedBy"] as? String
                
                // Get original canvas size
                var originalSize: CGSize?
                if let width = data["canvasWidth"] as? Double,
                   let height = data["canvasHeight"] as? Double {
                    originalSize = CGSize(width: width, height: height)
                }
                
                // Get drawing bounds
                var drawingBounds: CGRect?
                if let x = data["boundsX"] as? Double,
                   let y = data["boundsY"] as? Double,
                   let width = data["boundsWidth"] as? Double,
                   let height = data["boundsHeight"] as? Double {
                    drawingBounds = CGRect(x: x, y: y, width: width, height: height)
                }
                
                completion(drawingData, lastEditor, originalSize, drawingBounds)
            } else {
                completion(nil, nil, nil, nil)
            }
        }
    }
    
    // MARK: - Drawing Data Sync (Simultaneous Mode)
    
    func sendStroke(strokeData: Data, strokeId: String, userId: String, canvasSize: CGSize, originalUserId: String? = nil) {
        guard let roomCode = currentRoomCode else { return }
        
        let strokeRef = database.child("rooms").child(roomCode).child("strokes").child(strokeId)
        
        let data: [String: Any] = [
            "data": strokeData.base64EncodedString(),
            "userId": userId,
            "originalUserId": originalUserId ?? userId, // Track who ORIGINALLY created this stroke
            "timestamp": ServerValue.timestamp(),
            "canvasWidth": canvasSize.width,
            "canvasHeight": canvasSize.height
        ]
        
        strokeRef.setValue(data)
    }
    
    func observeStrokes(completion: @escaping (String, Data, String, String, CGSize?) -> Void) {
        guard let roomCode = currentRoomCode else { return }
        
        let strokesRef = database.child("rooms").child(roomCode).child("strokes")
        
        strokesRef.observe(.childAdded) { snapshot in
            if let data = snapshot.value as? [String: Any],
               let base64String = data["data"] as? String,
               let userId = data["userId"] as? String,
               let strokeData = Data(base64Encoded: base64String) {
                let strokeId = snapshot.key
                
                // Get original creator (defaults to sender if not specified)
                let originalUserId = data["originalUserId"] as? String ?? userId
                
                // Get canvas size if available
                var canvasSize: CGSize?
                if let width = data["canvasWidth"] as? Double,
                   let height = data["canvasHeight"] as? Double {
                    canvasSize = CGSize(width: width, height: height)
                }
                
                completion(strokeId, strokeData, userId, originalUserId, canvasSize)
            }
        }
    }
    
    // MARK: - Background Image Sync
    
    func sendBackgroundImage(_ imageData: Data, userId: String) {
        guard let roomCode = currentRoomCode else { return }
        
        let backgroundRef = database.child("rooms").child(roomCode).child("backgroundImage")
        
        let data: [String: Any] = [
            "data": imageData.base64EncodedString(),
            "userId": userId,
            "timestamp": ServerValue.timestamp()
        ]
        
        backgroundRef.setValue(data)
    }
    
    func observeBackgroundImage(completion: @escaping (Data?, String?) -> Void) {
        guard let roomCode = currentRoomCode else { return }
        
        let backgroundRef = database.child("rooms").child(roomCode).child("backgroundImage")
        
        backgroundRef.observe(.value) { snapshot in
            if let data = snapshot.value as? [String: Any],
               let base64String = data["data"] as? String,
               let imageData = Data(base64Encoded: base64String) {
                let userId = data["userId"] as? String
                completion(imageData, userId)
            } else {
                completion(nil, nil)
            }
        }
    }
    
    func clearBackgroundImage() {
        guard let roomCode = currentRoomCode else { return }
        
        let backgroundRef = database.child("rooms").child(roomCode).child("backgroundImage")
        backgroundRef.removeValue()
    }
    
    func clearCanvas() {
        guard let roomCode = currentRoomCode else { return }
        
        let drawingRef = database.child("rooms").child(roomCode).child("sharedDrawing")
        drawingRef.removeValue()
    }
    
    func leaveRoom() {
        currentRoomCode = nil
    }
    
    func stopObserving() {
        guard let roomCode = currentRoomCode else { return }
        let drawingRef = database.child("rooms").child(roomCode).child("sharedDrawing")
        drawingRef.removeAllObservers()
    }
}

