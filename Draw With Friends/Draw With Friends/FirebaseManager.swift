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
    static let maxUsersPerRoom = 4
    static let roomIdleLimit: TimeInterval = 24 * 60 * 60
    
    enum JoinRoomResult {
        case joined
        case notFound
        case full
        case expired
    }
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
            "lastActivity": ServerValue.timestamp(),
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
        
        let usersRef = database.child("rooms").child(roomCode).child("users")
        usersRef.observeSingleEvent(of: .value) { snapshot in
            completion(self.activeUserIds(from: snapshot.value as? [String: Any]))
        }
    }
    
    func registerUserInRoom(userId: String) {
        guard let roomCode = currentRoomCode else { return }
        
        let userRef = database.child("rooms").child(roomCode).child("users").child(userId)
        userRef.setValue([
            "joinedAt": ServerValue.timestamp(),
            "isActive": true
        ])
        userRef.onDisconnectUpdateChildValues(["isActive": false])
        touchLastActivity()
    }
    
    func joinRoom(code: String, userId: String, completion: @escaping (JoinRoomResult) -> Void) {
        let roomRef = database.child("rooms").child(code)
        
        roomRef.observeSingleEvent(of: .value) { snapshot in
            guard snapshot.exists(), let data = snapshot.value as? [String: Any] else {
                completion(.notFound)
                return
            }
            
            if self.isRoomExpired(data) {
                roomRef.removeValue()
                completion(.expired)
                return
            }
            
            let active = self.activeUserIds(from: data["users"] as? [String: Any])
            if active.count >= Self.maxUsersPerRoom && !active.contains(userId) {
                completion(.full)
                return
            }
            
            self.currentRoomCode = code
            completion(.joined)
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
        touchLastActivity()
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
        touchLastActivity()
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
    
    func deleteStroke(_ strokeId: String) {
        guard let roomCode = currentRoomCode else { return }
        database.child("rooms").child(roomCode).child("strokes").child(strokeId).removeValue()
    }
    
    func observeStrokeRemoved(completion: @escaping (String) -> Void) {
        guard let roomCode = currentRoomCode else { return }
        
        let strokesRef = database.child("rooms").child(roomCode).child("strokes")
        strokesRef.observe(.childRemoved) { snapshot in
            completion(snapshot.key)
        }
    }
    
    // MARK: - Full Canvas Sync (for eraser and periodic reconciliation)
    
    /// Send full canvas state - used after erasing or for periodic sync
    func sendFullCanvasSync(drawingData: Data, userId: String, canvasSize: CGSize, syncId: String, destructive: Bool = false) {
        guard let roomCode = currentRoomCode else { return }
        
        let syncRef = database.child("rooms").child(roomCode).child("fullCanvasSync")
        
        let data: [String: Any] = [
            "data": drawingData.base64EncodedString(),
            "userId": userId,
            "syncId": syncId,
            "timestamp": ServerValue.timestamp(),
            "canvasWidth": canvasSize.width,
            "canvasHeight": canvasSize.height,
            "destructive": destructive
        ]
        
        syncRef.setValue(data)
        touchLastActivity()
    }
    
    /// Observe full canvas sync events
    func observeFullCanvasSync(completion: @escaping (Data, String, String, CGSize?, Bool) -> Void) {
        guard let roomCode = currentRoomCode else { return }
        
        let syncRef = database.child("rooms").child(roomCode).child("fullCanvasSync")
        
        syncRef.observe(.value) { snapshot in
            if let data = snapshot.value as? [String: Any],
               let base64String = data["data"] as? String,
               let userId = data["userId"] as? String,
               let syncId = data["syncId"] as? String,
               let drawingData = Data(base64Encoded: base64String) {
                
                var canvasSize: CGSize?
                if let width = data["canvasWidth"] as? Double,
                   let height = data["canvasHeight"] as? Double {
                    canvasSize = CGSize(width: width, height: height)
                }
                let destructive = data["destructive"] as? Bool ?? false
                
                completion(drawingData, userId, syncId, canvasSize, destructive)
            }
        }
    }
    
    /// Clear all strokes from Firebase (used when full sync replaces stroke-by-stroke data)
    func clearAllStrokes() {
        guard let roomCode = currentRoomCode else { return }
        
        let strokesRef = database.child("rooms").child(roomCode).child("strokes")
        strokesRef.removeValue()
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
        touchLastActivity()
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
    
    func leaveRoom(userId: String) {
        guard let roomCode = currentRoomCode else { return }
        
        stopObserving()
        
        let roomRef = database.child("rooms").child(roomCode)
        let userRef = roomRef.child("users").child(userId)
        userRef.cancelDisconnectOperations()
        userRef.removeValue { _, _ in
            roomRef.child("users").observeSingleEvent(of: .value) { snapshot in
                let users = snapshot.value as? [String: Any]
                if users == nil || users?.isEmpty == true {
                    roomRef.removeValue()
                    return
                }
                if self.activeUserIds(from: users).isEmpty {
                    roomRef.child("backgroundImage").removeValue()
                }
            }
        }
        
        currentRoomCode = nil
    }
    
    private func touchLastActivity() {
        guard let roomCode = currentRoomCode else { return }
        database.child("rooms").child(roomCode).child("lastActivity").setValue(ServerValue.timestamp())
    }
    
    private func isRoomExpired(_ data: [String: Any]) -> Bool {
        let last = firebaseSeconds(data["lastActivity"]) ?? firebaseSeconds(data["createdAt"])
        guard let last else { return false }
        return Date().timeIntervalSince1970 - last > Self.roomIdleLimit
    }
    
    private func firebaseSeconds(_ value: Any?) -> TimeInterval? {
        if let number = value as? Double {
            return number > 10_000_000_000 ? number / 1000 : number
        }
        if let number = value as? Int {
            let value = Double(number)
            return value > 10_000_000_000 ? value / 1000 : value
        }
        return nil
    }
    
    private func activeUserIds(from users: [String: Any]?) -> [String] {
        guard let users else { return [] }
        return users.compactMap { userId, raw in
            if let info = raw as? [String: Any], let isActive = info["isActive"] as? Bool, !isActive {
                return nil
            }
            return userId
        }
    }
    
    func stopObserving() {
        guard let roomCode = currentRoomCode else { return }
        let room = database.child("rooms").child(roomCode)
        room.removeAllObservers()
        room.child("sharedDrawing").removeAllObservers()
        room.child("strokes").removeAllObservers()
        room.child("fullCanvasSync").removeAllObservers()
        room.child("currentTurn").removeAllObservers()
        room.child("backgroundImage").removeAllObservers()
        room.child("paper").removeAllObservers()
    }
    
    // MARK: - Shared paper size (same drawing coordinates on every device)
    
    /// First device to write wins. Later devices must draw in this coordinate space.
    func publishPaperSizeIfNeeded(_ size: CGSize) {
        guard let roomCode = currentRoomCode, size.width > 32, size.height > 32 else { return }
        
        let paperRef = database.child("rooms").child(roomCode).child("paper")
        paperRef.runTransactionBlock { current in
            if current.value == nil || current.value is NSNull {
                current.value = [
                    "width": Double(size.width),
                    "height": Double(size.height)
                ]
            }
            return TransactionResult.success(withValue: current)
        }
    }
    
    func observePaperSize(completion: @escaping (CGSize) -> Void) {
        guard let roomCode = currentRoomCode else { return }
        
        database.child("rooms").child(roomCode).child("paper").observe(.value) { snapshot in
            guard let data = snapshot.value as? [String: Any],
                  let width = Self.cgFloat(data["width"]),
                  let height = Self.cgFloat(data["height"]),
                  width > 32, height > 32 else { return }
            completion(CGSize(width: width, height: height))
        }
    }
    
    private static func cgFloat(_ value: Any?) -> CGFloat? {
        if let number = value as? Double { return CGFloat(number) }
        if let number = value as? Int { return CGFloat(number) }
        if let number = value as? NSNumber { return CGFloat(number.doubleValue) }
        return nil
    }
}

