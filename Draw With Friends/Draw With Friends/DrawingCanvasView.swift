//
//  DrawingCanvasView.swift
//  Draw With Friends
//
//  Created by Jamie on 09/11/2025.
//

import SwiftUI
import Combine
import PencilKit
import PhotosUI

struct DrawingCanvasView: View {
    @StateObject private var firebaseManager = FirebaseManager.shared
    @StateObject private var canvasViewModel = CanvasViewModel()
    @State private var showRoomCode = true
    @State private var selectedColor: Color = .black
    @State private var showColorPicker = false
    @State private var showSaveDialog = false
    @State private var showSavedDrawings = false
    @State private var showExportSuccess = false
    @State private var showExportError = false
    @State private var drawingName = ""
    @State private var echoModeEnabled = false
    @State private var echoCount = 2 // Number of echo copies (2 = 2 echoes + 1 original = 3 total), 0 = infinite
    @State private var showDiagnostics = false
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var backgroundImage: UIImage?
    @State private var showCopiedConfirmation = false
    @State private var showPhotoSharingWarning = false
    @State private var pendingPhotoItem: PhotosPickerItem?
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    // Drawing tool state
    private enum ToolType {
        case pencil
        case brush
        case spray
    }
    @State private var selectedTool: ToolType = .pencil
    @State private var lineWidth: CGFloat = 5
    
    // MARK: - Toolbar View
    private var toolbarView: some View {
        VStack(spacing: 8) {
            HStack(spacing: 16) {
                // Color picker
                Button(action: { showColorPicker.toggle() }) {
                    Circle()
                        .fill(selectedColor)
                        .frame(width: 36, height: 36)
                        .overlay(Circle().stroke(Color.white, lineWidth: 2))
                        .shadow(radius: 1)
                }
                
                // Tool buttons
                HStack(spacing: 12) {
                    ToolButton(icon: "pencil.tip", isActive: selectedTool == .pencil) { 
                        selectedTool = .pencil
                    }
                    ToolButton(icon: "paintbrush.pointed.fill", isActive: selectedTool == .brush) { 
                        selectedTool = .brush
                    }
                    ToolButton(icon: "paintbrush.pointed", isActive: selectedTool == .spray) { 
                        selectedTool = .spray
                    }
                }
                
                // Thickness slider
                HStack(spacing: 8) {
                    Image(systemName: "line.diagonal")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.8))
                    Slider(value: $lineWidth, in: 1...30, step: 1)
                        .frame(maxWidth: 240)
                    Text("\(Int(lineWidth))")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.8))
                        .frame(width: 28, alignment: .leading)
                }
            }
            
            HStack(spacing: 16) {
                // Import photo button
                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    Image(systemName: "photo.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 50, height: 50)
                        .background(
                            LinearGradient(
                                colors: [Color.green, Color.teal],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(Circle())
                        .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                }
                
                // Export button in toolbar
                Button(action: exportAsImage) {
                    Image(systemName: "square.and.arrow.up.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 50, height: 50)
                        .background(
                            LinearGradient(
                                colors: [Color.blue, Color.purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(Circle())
                        .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                }
                
                Button(action: {
                    if canvasViewModel.canvasView.drawing.strokes.count > 0 {
                        var drawing = canvasViewModel.canvasView.drawing
                        drawing.strokes.removeLast()
                        canvasViewModel.canvasView.drawing = drawing
                    }
                }) {
                    Label("Undo", systemImage: "arrow.uturn.backward")
                        .labelStyle(.iconOnly)
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.blue)
                        .clipShape(Capsule())
                }
                
                // Echo Drawing Tool (works in both simultaneous and turn-based modes)
                HStack(spacing: 8) {
                    // Echo toggle button
                    Button(action: {
                        echoModeEnabled.toggle()
                        canvasViewModel.echoModeEnabled = echoModeEnabled
                        canvasViewModel.echoCount = echoCount
                        canvasViewModel.logEchoStateChange()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "waveform.path")
                            Text(echoModeEnabled ? "Echo" : "Echo Off")
                                .font(.caption)
                        }
                        .foregroundColor(.white)
                        .padding(8)
                        .background(echoModeEnabled ? Color.purple : Color.gray)
                        .clipShape(Capsule())
                    }
                    
                    // Echo count controls (only show when enabled)
                    if echoModeEnabled {
                        HStack(spacing: 4) {
                            // Minus button
                            Button(action: {
                                if echoCount > 0 {
                                    echoCount -= 1
                                    canvasViewModel.echoCount = echoCount
                                    canvasViewModel.logEchoStateChange()
                                }
                            }) {
                                Image(systemName: "minus.circle.fill")
                                    .font(.body)
                                    .foregroundColor(.white)
                            }
                            
                            // Count display
                            Text(echoCount == 0 ? "∞" : "\(echoCount)")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .frame(minWidth: 20)
                            
                            // Plus button
                            Button(action: {
                                if echoCount < 10 {
                                    echoCount += 1
                                    canvasViewModel.echoCount = echoCount
                                    canvasViewModel.logEchoStateChange()
                                } else if echoCount == 10 {
                                    echoCount = 0 // Wrap to infinite
                                    canvasViewModel.echoCount = echoCount
                                    canvasViewModel.logEchoStateChange()
                                }
                            }) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.body)
                                    .foregroundColor(.white)
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(Color.purple.opacity(0.8))
                        .clipShape(Capsule())
                    }
                }
            }
        }
        .padding()
        .background(Color.black.opacity(0.05))
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // HEADER - Status and controls (no overlap with canvas!)
                VStack(spacing: 0) {
                // Status message banner
                Text(canvasViewModel.statusMessage)
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity)
                    .background(canvasViewModel.isMyTurn ? Color.green : Color.orange)
                
                // Pass Turn button (only show if it's my turn and turn-based)
                if canvasViewModel.isMyTurn && !canvasViewModel.statusMessage.contains("together") {
                    Button(action: {
                        canvasViewModel.passTurnToNext()
                    }) {
                        HStack {
                            Image(systemName: "arrow.right.circle.fill")
                            Text("Pass Turn")
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                    }
                }
                
                // Room controls row
                HStack {
                    // Diagnostics button (top-left)
                    DiagnosticsToggleButton(isShowing: $showDiagnostics)
                    
                    if let roomCode = firebaseManager.currentRoomCode {
                        HStack {
                            Text("Room: \(roomCode)")
                                .font(.caption)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.white.opacity(0.9))
                                .cornerRadius(15)
                                .onAppear {
                                    print("🏠🏠🏠 THIS DEVICE IS IN ROOM: \(roomCode)")
                                    print("🏠🏠🏠 My UserId: \(UserSession.shared.userId)")
                                }
                            
                            Button(action: {
                                UIPasteboard.general.string = roomCode
                                showCopiedConfirmation = true
                                
                                // Hide confirmation after 2 seconds
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    showCopiedConfirmation = false
                                }
                            }) {
                                Image(systemName: "doc.on.doc")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                                    .padding(6)
                                    .background(Color.white.opacity(0.9))
                                    .clipShape(Circle())
                            }
                        }
                    }
                    
                    Spacer()
                    
                    Button(action: clearCanvas) {
                        Image(systemName: "trash")
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(6)
                            .background(Color.white.opacity(0.9))
                            .clipShape(Circle())
                    }
                    
                    Button(action: leaveRoom) {
                        Image(systemName: "xmark")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding(6)
                            .background(Color.white.opacity(0.9))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color.black.opacity(0.05))
            }
            
            // CANVAS - Takes up remaining space
            GeometryReader { geometry in
                ZStack {
                    // Default light background
                    Color(white: 0.98)
                    
                    // Background image if selected
                    if let backgroundImage = backgroundImage {
                        Image(uiImage: backgroundImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .clipped()
                    }
                    
                    // Drawing canvas on top
                    CanvasView(
                        canvasView: $canvasViewModel.canvasView,
                        onDrawingChanged: { drawing in
                            canvasViewModel.handleDrawingChange(drawing)
                        },
                        onDrawingStarted: {
                            canvasViewModel.handleDrawingStarted()
                        },
                        onDrawingEnded: {
                            canvasViewModel.handleDrawingEnded()
                        }
                    )
                }
                .onAppear {
                    canvasViewModel.currentCanvasSize = geometry.size
                }
                .onChange(of: geometry.size) { newSize in
                    canvasViewModel.currentCanvasSize = newSize
                }
            }
            
            // TOOLS - Bottom bar
            toolbarView
                .onChange(of: selectedTool) { _ in updateTool() }
                .onChange(of: lineWidth) { _ in updateTool() }
                .onChange(of: selectedColor) { _ in updateTool() }
                .onAppear { updateTool() }
            }
            
            // Color picker overlay
            if showColorPicker {
                ZStack {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .onTapGesture {
                            showColorPicker = false
                        }
                    
                    VStack {
                        Text("Choose Color")
                            .font(.headline)
                            .padding()
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 15) {
                            ForEach(ColorOption.allColors, id: \.self) { colorOption in
                                Circle()
                                    .fill(colorOption.color)
                                    .frame(width: 50, height: 50)
                                    .overlay(
                                        Circle()
                                            .stroke(selectedColor == colorOption.color ? Color.white : Color.clear, lineWidth: 3)
                                    )
                                    .onTapGesture {
                                        selectedColor = colorOption.color
                                        canvasViewModel.setColor(colorOption.color)
                                        showColorPicker = false
                                    }
                            }
                        }
                        .padding()
                    }
                    .background(Color.white)
                    .cornerRadius(20)
                    .padding(40)
                }
            }
            
            // Diagnostics overlay
            if showDiagnostics {
                VStack {
                    DiagnosticsView()
                        .padding()
                    Spacer()
                }
                .transition(.move(edge: .top))
            }
            
            // Copied confirmation toast
            if showCopiedConfirmation {
                VStack {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.white)
                        Text("Room code copied!")
                            .foregroundColor(.white)
                            .fontWeight(.semibold)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.green)
                    .cornerRadius(25)
                    .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
                    .padding(.top, 100)
                    
                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(.spring(), value: showCopiedConfirmation)
            }
            
        }
        .onAppear {
            canvasViewModel.startObserving()
            updateTool()
            
            // Observe background images from other users
            firebaseManager.observeBackgroundImage { imageData, userId in
                // Only apply if it's from another user (not myself)
                if let imageData = imageData,
                   userId != UserSession.shared.userId,
                   let image = UIImage(data: imageData) {
                    DispatchQueue.main.async {
                        self.backgroundImage = image
                    }
                }
            }
        }
        .onChange(of: selectedPhoto) { newPhoto in
            if let newPhoto = newPhoto {
                // Check if user has seen the warning before
                let hasSeenWarning = UserDefaults.standard.bool(forKey: "hasSeenPhotoSharingWarning")
                
                if hasSeenWarning {
                    // Proceed directly
                    loadAndSharePhoto(newPhoto)
                } else {
                    // Show warning first
                    pendingPhotoItem = newPhoto
                    showPhotoSharingWarning = true
                }
            }
        }
        .sheet(isPresented: $showSavedDrawings) {
            SavedDrawingsView { drawing in
                canvasViewModel.loadDrawing(drawing)
            }
        }
        .alert("Save Drawing", isPresented: $showSaveDialog) {
            TextField("Drawing name", text: $drawingName)
            Button("Cancel", role: .cancel) {
                drawingName = ""
            }
            Button("Save") {
                saveDrawing()
            }
        } message: {
            Text("Give your drawing a name")
        }
        .alert("Exported!", isPresented: $showExportSuccess) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Drawing saved to Photos")
        }
        .alert("Export Failed", isPresented: $showExportError) {
            Button("OK", role: .cancel) { }
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
        } message: {
            Text("Unable to save to Photos. Please check app permissions in Settings.")
        }
        .alert("Share Photo with Room?", isPresented: $showPhotoSharingWarning) {
            Button("Cancel", role: .cancel) {
                // Clear the pending photo
                pendingPhotoItem = nil
                selectedPhoto = nil
            }
            Button("Share") {
                // Save preference so they don't see this again
                UserDefaults.standard.set(true, forKey: "hasSeenPhotoSharingWarning")
                
                // Proceed with loading the photo
                if let pending = pendingPhotoItem {
                    loadAndSharePhoto(pending)
                }
                pendingPhotoItem = nil
            }
        } message: {
            Text("This photo will be uploaded to our servers and shared with everyone in your drawing room. Only import photos you're comfortable sharing.")
        }
    }
    
    private func saveDrawing() {
        let name = drawingName.isEmpty ? nil : drawingName
        DrawingManager.shared.saveDrawing(canvasViewModel.canvasView.drawing, name: name)
        drawingName = ""
    }
    
    private func loadAndSharePhoto(_ photoItem: PhotosPickerItem) {
        Task {
            if let data = try? await photoItem.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                backgroundImage = image
                
                // Compress and send to Firebase so others can see it
                if let compressedData = image.jpegData(compressionQuality: 0.6) {
                    firebaseManager.sendBackgroundImage(compressedData, userId: UserSession.shared.userId)
                }
            }
        }
    }
    
    private func exportAsImage() {
        guard let image = DrawingManager.shared.exportAsImage(
            canvasViewModel.canvasView.drawing,
            backgroundImage: backgroundImage,
            canvasSize: canvasViewModel.currentCanvasSize
        ) else {
            showExportError = true
            return
        }
        
        DrawingManager.shared.saveToPhotos(image) { success in
            if success {
                showExportSuccess = true
            } else {
                showExportError = true
            }
        }
    }
    
    private func clearCanvas() {
        canvasViewModel.canvasView.drawing = PKDrawing()
        canvasViewModel.resetStrokeTracking() // Clear reconciliation data
        firebaseManager.clearCanvas()
        
        // Also clear background image
        backgroundImage = nil
        firebaseManager.clearBackgroundImage()
    }
    
    private func leaveRoom() {
        firebaseManager.stopObserving()
        firebaseManager.leaveRoom()
        // This should trigger navigation back to room selection
    }
    
    // Update the active PencilKit tool based on selected tool, color and thickness
    private func updateTool() {
        let base = UIColor(selectedColor)
        let inkType: PKInkingTool.InkType
        let color: UIColor
        switch selectedTool {
        case .pencil:
            inkType = .pencil
            color = base
        case .brush:
            inkType = .pen  // Smooth, consistent strokes
            color = base
        case .spray:
            inkType = .marker  // Semi-transparent, painterly
            color = base.withAlphaComponent(0.35)
        }
        canvasViewModel.canvasView.tool = PKInkingTool(inkType, color: color, width: max(1, lineWidth))
    }
}

// MARK: - Canvas View (UIKit wrapper)

struct CanvasView: UIViewRepresentable {
    @Binding var canvasView: PKCanvasView
    var onDrawingChanged: (PKDrawing) -> Void
    var onDrawingStarted: () -> Void
    var onDrawingEnded: () -> Void
    
    func makeUIView(context: Context) -> PKCanvasView {
        canvasView.tool = PKInkingTool(.pen, color: .black, width: 3)
        canvasView.drawingPolicy = .anyInput
        canvasView.delegate = context.coordinator
        
        // Disable auto-zoom to prevent "empty space" around scaled drawings
        canvasView.minimumZoomScale = 1.0
        canvasView.maximumZoomScale = 1.0
        canvasView.zoomScale = 1.0
        
        // Transparent background so we can see images behind it
        canvasView.backgroundColor = .clear
        canvasView.isOpaque = false
        
        return canvasView
    }
    
    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        // Updates handled by coordinator
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(
            onDrawingChanged: onDrawingChanged,
            onDrawingStarted: onDrawingStarted,
            onDrawingEnded: onDrawingEnded
        )
    }
    
    class Coordinator: NSObject, PKCanvasViewDelegate {
        var onDrawingChanged: (PKDrawing) -> Void
        var onDrawingStarted: () -> Void
        var onDrawingEnded: () -> Void
        
        init(onDrawingChanged: @escaping (PKDrawing) -> Void,
             onDrawingStarted: @escaping () -> Void,
             onDrawingEnded: @escaping () -> Void) {
            self.onDrawingChanged = onDrawingChanged
            self.onDrawingStarted = onDrawingStarted
            self.onDrawingEnded = onDrawingEnded
        }
        
        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            onDrawingChanged(canvasView.drawing)
        }
        
        func canvasViewDidBeginUsingTool(_ canvasView: PKCanvasView) {
            onDrawingStarted()
        }
        
        func canvasViewDidEndUsingTool(_ canvasView: PKCanvasView) {
            onDrawingEnded()
        }
    }
}

// MARK: - ViewModel

class CanvasViewModel: ObservableObject {
    @Published var canvasView = PKCanvasView()
    @Published var isMyTurn = false
    @Published var currentTurnUserId: String?
    @Published var statusMessage = "Loading..."
    @Published var echoModeEnabled = false
    @Published var echoCount = 2 // Number of times to echo (1 = no echo, 2-10 = limited, 0 = infinite)
    private var echoEnabledStrokeCount = 0 // Track stroke count when echo was enabled
    
    private let firebaseManager = FirebaseManager.shared
    private let diagnostics = DiagnosticsManager.shared
    private var isReceivingUpdate = false
    private var syncTimer: Timer?
    private var lastLocalDrawing: Data?
    private var roomMode: String?
    var currentCanvasSize: CGSize = .zero
    
    // Smart timer management - pause during inactivity
    private var lastActivityTime: Date = Date()
    private var isSyncTimerActive = true
    private let inactivityThreshold: TimeInterval = 5.0 // Pause after 5 seconds of no activity
    
    // Track what we've actually drawn vs received
    private var myStrokeCount = 0 // How many strokes I actually drew
    private var lastSyncedStrokeCount = 0 // How many strokes were in last sync
    
    // For simultaneous mode - stroke reconciliation system
    private struct StrokeInfo {
        let id: String
        let data: Data
        let timestamp: Double
        let originalSize: CGSize?
        let originalUserId: String
        var stroke: PKStroke? // Cached decoded stroke
    }
    
    private var allKnownStrokes: [String: StrokeInfo] = [:] // All strokes by ID (mine + others)
    private var strokeOrder: [String] = [] // Ordered list of stroke IDs (by timestamp)
    private var lastCanvasStrokeCount = 0 // Track canvas size to detect new local strokes
    private var isRebuilding = false // Prevent recursive rebuilds
    private var isUserDrawing = false // Track if user is actively drawing
    private var needsRebuild = false // Flag to rebuild after user finishes drawing
    private var echoedStrokeIds: Set<String> = [] // Track echoed strokes
    private var strokeEchoCounts: [String: Int] = [:] // Track echo counts for limited echo mode
    
    private var userId: String {
        return UserSession.shared.userId
    }
    
    func startObserving() {
        diagnostics.logInfo("Starting observation - userId: \(userId.prefix(8))")
        diagnostics.updateMetrics(roomCode: firebaseManager.currentRoomCode, userId: userId)
        diagnostics.logConnection(status: "Connecting")
        
        // Register user in room
        firebaseManager.registerUserInRoom(userId: userId)
        
        // Get the room mode
        firebaseManager.getRoomMode { [weak self] (mode: String?) in
            guard let self = self else { return }
            
            self.diagnostics.logInfo("Room mode: '\(mode ?? "nil")'")
            self.roomMode = mode
            
            if mode == "turnBased" {
                self.diagnostics.logInfo("Starting TURN-BASED mode")
                self.startTurnBasedMode()
            } else {
                self.diagnostics.logInfo("Starting SIMULTANEOUS mode")
                self.statusMessage = "Draw together!"
                self.isMyTurn = true // Always enabled in simultaneous
                self.canvasView.isUserInteractionEnabled = true
                self.startSimultaneousMode()
            }
            
            self.diagnostics.logConnection(status: "Connected")
        }
    }
    
    // MARK: - Turn-Based Mode
    
    private func startTurnBasedMode() {
        print("🎮 startTurnBasedMode() - Setting up turn observation")
        
        // Observe whose turn it is
        firebaseManager.observeCurrentTurn { [weak self] (turnUserId: String?) in
            guard let self = self else { return }
            
            self.currentTurnUserId = turnUserId
            self.isMyTurn = (turnUserId == self.userId)
            
            print("🔄 Turn Update: userId=\(self.userId), turnUserId=\(turnUserId ?? "nil"), isMyTurn=\(self.isMyTurn)")
            
            // Lock/unlock canvas based on turn
            DispatchQueue.main.async {
                self.canvasView.isUserInteractionEnabled = self.isMyTurn
                self.canvasView.drawingPolicy = self.isMyTurn ? .anyInput : .default
                
                if self.isMyTurn {
                    self.statusMessage = "🎨 YOUR TURN! Draw now"
                    print("✅ Canvas ENABLED for drawing")
                    // Reset stroke count tracking when we start our turn
                    self.lastSyncedStrokeCount = self.canvasView.drawing.strokes.count
                } else {
                    self.statusMessage = "⏳ Friend is drawing... Please wait"
                    print("🔒 Canvas DISABLED - not your turn")
                }
            }
        }
        
        // Observe drawing changes
        firebaseManager.observeSharedDrawing { [weak self] (drawingData: Data?, lastEditor: String?, originalSize: CGSize?, originalBounds: CGRect?) in
            guard let self = self else { return }
            
            print("📨 Firebase callback: hasData=\(drawingData != nil), editor=\(lastEditor ?? "nil"), myId=\(self.userId)")
            
            if let data = drawingData, lastEditor != self.userId {
                print("   📥 RECEIVING from other user")
                print("      Original canvas: \(originalSize ?? .zero)")
                print("      Original bounds: \(originalBounds?.debugDescription ?? "nil")")
                print("      My canvas: \(self.currentCanvasSize)")
                print("      isMyTurn: \(self.isMyTurn)")
                
                // Skip if it's not our turn (shouldn't be receiving updates during our turn)
                if self.isMyTurn {
                    print("      ⏭️ Skip: It's my turn")
                    return
                }
                
                // Mark activity to keep sync timer alive
                self.markActivity()
                
                self.isReceivingUpdate = true
                
                if var drawing = try? PKDrawing(data: data) {
                    print("      ✅ Decoded: \(drawing.strokes.count) strokes")
                    
                    // Scale drawing based on content bounds if available, otherwise use canvas size
                    if let origSize = originalSize, let origBounds = originalBounds, 
                       self.currentCanvasSize != .zero, origSize != self.currentCanvasSize {
                        print("      🔄 SCALING using content-aware method")
                        let before = drawing.bounds
                        drawing = self.scaleDrawingContentAware(drawing, 
                                                                 originalCanvas: origSize, 
                                                                 originalBounds: origBounds,
                                                                 targetCanvas: self.currentCanvasSize)
                        print("      📐 Bounds: \(before) → \(drawing.bounds)")
                    } else if let origSize = originalSize, self.currentCanvasSize != .zero, origSize != self.currentCanvasSize {
                        // Fallback to simple canvas scaling
                        print("      🔄 SCALING from \(origSize) to \(self.currentCanvasSize)")
                        let before = drawing.bounds
                        drawing = self.scaleDrawing(drawing, from: origSize, to: self.currentCanvasSize)
                        print("      📐 Bounds: \(before) → \(drawing.bounds)")
                    } else {
                        print("      ⏸️ No scaling (sizes match or unavailable)")
                    }
                    
                    DispatchQueue.main.async {
                        print("      🖼️ Applying to canvas")
                        self.canvasView.drawing = drawing
                        self.lastLocalDrawing = data
                        self.lastSyncedStrokeCount = drawing.strokes.count
                        
                        // Update echo tracking counter to match received drawing
                        self.echoEnabledStrokeCount = drawing.strokes.count
                        
                        self.isReceivingUpdate = false
                        print("      ✅ Done applying")
                    }
                } else {
                    print("      ❌ Failed to decode")
                    self.isReceivingUpdate = false
                }
            } else {
                print("   ⏭️ Skip: No data or from myself")
            }
        }
        
        syncTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.syncTurnBased()
        }
    }
    
    private func syncTurnBased() {
        // Check for inactivity and pause timer if idle
        let timeSinceActivity = Date().timeIntervalSince(lastActivityTime)
        if timeSinceActivity > inactivityThreshold && isSyncTimerActive {
            isSyncTimerActive = false
            diagnostics.logInfo("⏸️ Sync timer PAUSED due to inactivity (\(Int(timeSinceActivity))s idle)")
            return
        }
        
        // Only log and sync if timer is active
        guard isSyncTimerActive else { return }
        
        let currentDrawing = canvasView.drawing
        let currentCount = currentDrawing.strokes.count
        
        diagnostics.logInfo("🔄 Sync Timer: strokes=\(currentCount), lastSynced=\(lastSyncedStrokeCount), isMyTurn=\(isMyTurn), isReceiving=\(isReceivingUpdate), canvasSize=\(currentCanvasSize)")
        
        guard !isReceivingUpdate else {
            diagnostics.logInfo("   ⏸️ Skip: Currently receiving update")
            return
        }
        guard currentCanvasSize != .zero else {
            print("   ⏸️ Skip: Canvas size is zero")
            return
        }
        
        // Only sync if it's our turn
        guard isMyTurn else {
            print("   ⏸️ Skip: Not my turn")
            return
        }
        
        // Don't sync empty drawings
        if currentCount == 0 {
            print("   ⏸️ Skip: Drawing is empty")
            return
        }
        
        // Only sync if we have NEW strokes since last sync
        if currentCount > lastSyncedStrokeCount {
            // Mark activity to keep sync timer alive
            markActivity()
            
            let drawingBounds = currentDrawing.bounds
            diagnostics.logInfo("   ✅ SENDING: \(currentCount) strokes (was \(lastSyncedStrokeCount)), canvas: \(currentCanvasSize), bounds: \(drawingBounds)")
            let newData = currentDrawing.dataRepresentation()
            firebaseManager.sendDrawing(newData, userId: userId, canvasSize: currentCanvasSize, drawingBounds: drawingBounds)
            lastLocalDrawing = newData
            lastSyncedStrokeCount = currentCount
        } else {
            print("   ⏸️ Skip: No new strokes (\(currentCount) == \(lastSyncedStrokeCount))")
        }
    }
    
    // Simple uniform scaling with centering: preserves aspect ratio, centers the drawing
    private func scaleDrawingContentAware(_ drawing: PKDrawing, 
                                          originalCanvas: CGSize,
                                          originalBounds: CGRect,
                                          targetCanvas: CGSize) -> PKDrawing {
        // Validate inputs
        guard originalCanvas.width > 0, originalCanvas.height > 0,
              targetCanvas.width > 0, targetCanvas.height > 0,
              originalCanvas.width.isFinite, originalCanvas.height.isFinite,
              targetCanvas.width.isFinite, targetCanvas.height.isFinite else {
            print("         ⚠️ INVALID INPUT! Original: \(originalCanvas), Target: \(targetCanvas) - returning original")
            return drawing
        }
        
        // Simple uniform scale based on canvas dimensions
        let scaleX = targetCanvas.width / originalCanvas.width
        let scaleY = targetCanvas.height / originalCanvas.height
        
        guard scaleX.isFinite, scaleY.isFinite, scaleX > 0, scaleY > 0 else {
            print("         ⚠️ INVALID SCALES! scaleX: \(scaleX), scaleY: \(scaleY) - returning original")
            return drawing
        }
        
        let scale = min(scaleX, scaleY)
        
        // Calculate centering offset
        let scaledWidth = originalCanvas.width * scale
        let scaledHeight = originalCanvas.height * scale
        let offsetX = (targetCanvas.width - scaledWidth) / 2.0
        let offsetY = (targetCanvas.height - scaledHeight) / 2.0
        
        guard offsetX.isFinite, offsetY.isFinite else {
            print("         ⚠️ INVALID OFFSETS! offsetX: \(offsetX), offsetY: \(offsetY) - returning original")
            return drawing
        }
        
        print("         Uniform scaling: \(originalCanvas) → \(targetCanvas)")
        print("         Scale: \(scale), Offset: (\(offsetX), \(offsetY))")
        
        // Apply scale + offset to center the drawing
        var transform = CGAffineTransform(scaleX: scale, y: scale)
        transform = transform.translatedBy(x: offsetX / scale, y: offsetY / scale)
        
        let scaled = drawing.transformed(using: transform)
        
        print("         Result bounds: \(scaled.bounds)")
        
        return scaled
    }
    
    // Simple canvas-to-canvas scaling with centering
    private func scaleDrawing(_ drawing: PKDrawing, from originalSize: CGSize, to newSize: CGSize) -> PKDrawing {
        // Validate inputs - prevent division by zero or invalid dimensions
        guard originalSize.width > 0, originalSize.height > 0,
              newSize.width > 0, newSize.height > 0,
              originalSize.width.isFinite, originalSize.height.isFinite,
              newSize.width.isFinite, newSize.height.isFinite else {
            print("   ⚠️ INVALID SCALE INPUT! Original: \(originalSize), New: \(newSize) - returning original")
            return drawing
        }
        
        let scaleX = newSize.width / originalSize.width
        let scaleY = newSize.height / originalSize.height
        
        // Validate scale factors
        guard scaleX.isFinite, scaleY.isFinite, scaleX > 0, scaleY > 0 else {
            print("   ⚠️ INVALID SCALE FACTORS! scaleX: \(scaleX), scaleY: \(scaleY) - returning original")
            return drawing
        }
        
        // Use UNIFORM scaling to preserve aspect ratio
        let scale = min(scaleX, scaleY)
        
        // Calculate centering offset
        let scaledWidth = originalSize.width * scale
        let scaledHeight = originalSize.height * scale
        let offsetX = (newSize.width - scaledWidth) / 2.0
        let offsetY = (newSize.height - scaledHeight) / 2.0
        
        // Validate final values
        guard offsetX.isFinite, offsetY.isFinite else {
            print("   ⚠️ INVALID OFFSETS! offsetX: \(offsetX), offsetY: \(offsetY) - returning original")
            return drawing
        }
        
        print("   📐 Scale: \(scale), Offset: (\(offsetX), \(offsetY))")
        print("   📐 Drawing bounds before: \(drawing.bounds)")
        
        // Apply scale + offset to center the drawing
        var transform = CGAffineTransform(scaleX: scale, y: scale)
        transform = transform.translatedBy(x: offsetX / scale, y: offsetY / scale)
        
        let scaled = drawing.transformed(using: transform)
        
        print("   📐 Drawing bounds after: \(scaled.bounds)")
        
        return scaled
    }
    
    // MARK: - Simultaneous Mode
    
    private func startSimultaneousMode() {
        print("🎨🎨 SIMULTANEOUS MODE STARTING")
        print("   My userId: \(userId)")
        print("   Setting up stroke observer...")
        
        // Observe incoming strokes from others
        firebaseManager.observeStrokes { [weak self] (strokeId: String, strokeData: Data, senderId: String, originalUserId: String, canvasSize: CGSize?) in
            guard let self = self else { return }
            
            let timestamp = Date().timeIntervalSince1970
            
            // Check if this is our own stroke
            let isOwnStroke = (senderId == self.userId && originalUserId == self.userId)
            
            // Log the received stroke
            self.diagnostics.logStrokeReceived(strokeId: strokeId, fromUser: senderId, isOwn: isOwnStroke)
            
            // Ignore my own strokes (already in allKnownStrokes)
            if self.allKnownStrokes[strokeId] != nil {
                return
            }
            
            // Don't add own strokes
            if isOwnStroke {
                return
            }
            
            // Mark activity to keep sync timer alive when receiving strokes
            self.markActivity()
            
            // Add to our known strokes collection
            let strokeInfo = StrokeInfo(
                id: strokeId,
                data: strokeData,
                timestamp: timestamp,
                originalSize: canvasSize,
                originalUserId: originalUserId,
                stroke: nil
            )
            
            self.diagnostics.logInfo("Adding stroke to collection (total: \(self.allKnownStrokes.count + 1))")
            self.allKnownStrokes[strokeId] = strokeInfo
            self.strokeOrder.append(strokeId)
            self.strokeOrder.sort { id1, id2 in
                let t1 = self.allKnownStrokes[id1]?.timestamp ?? 0
                let t2 = self.allKnownStrokes[id2]?.timestamp ?? 0
                return t1 < t2
            }
            
            self.rebuildCanvas()
            
            // NOTE: We do NOT echo received strokes!
            // Echo mode only applies to YOUR OWN strokes (in captureNewLocalStrokes).
            // When you receive strokes from others, they're already echoed if they had echo enabled.
            // This ensures both devices see exactly the same thing.
        }
        
        print("   Setting up sync timer (0.5s interval)...")
        syncTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.syncSimultaneous()
        }
        print("   ✅ Sync timer started")
    }
    
    // Mark activity to keep sync timer running
    private func markActivity() {
        let wasInactive = !isSyncTimerActive
        lastActivityTime = Date()
        isSyncTimerActive = true
        
        if wasInactive {
            diagnostics.logInfo("▶️ Sync timer RESUMED (activity detected)")
        }
    }
    
    private func syncSimultaneous() {
        // Check for inactivity and pause timer if idle
        let timeSinceActivity = Date().timeIntervalSince(lastActivityTime)
        if timeSinceActivity > inactivityThreshold && isSyncTimerActive {
            isSyncTimerActive = false
            diagnostics.logInfo("⏸️ Sync timer PAUSED due to inactivity (\(Int(timeSinceActivity))s idle)")
            // Timer continues running but does nothing - very low overhead
            return
        }
        
        // Only log and sync if timer is active
        guard isSyncTimerActive else { return }
        
        guard !isRebuilding else {
            // Skip sync if rebuilding (only log if diagnostics enabled)
            return
        }
        
        captureNewLocalStrokes()
    }
    
    // Capture any new local strokes and add them to the collection
    private func captureNewLocalStrokes() {
        let currentStrokes = canvasView.drawing.strokes
        let timestamp = Date().timeIntervalSince1970
        
        // Detect new LOCAL strokes drawn by user
        if currentStrokes.count > lastCanvasStrokeCount {
            let newCount = currentStrokes.count - lastCanvasStrokeCount
            
            // Mark activity to keep sync timer alive
            markActivity()
            
            // Get the new strokes from the end
            let newStrokes = Array(currentStrokes.suffix(newCount))
            
            for (index, stroke) in newStrokes.enumerated() {
                // Create unique ID and serialize
                let strokeId = UUID().uuidString
                var singleStrokeDrawing = PKDrawing()
                singleStrokeDrawing.strokes = [stroke]
                let strokeData = singleStrokeDrawing.dataRepresentation()
                
                // Add to our known strokes IMMEDIATELY
                let strokeInfo = StrokeInfo(
                    id: strokeId,
                    data: strokeData,
                    timestamp: timestamp + Double(index) * 0.001, // Slight offset to maintain order
                    originalSize: currentCanvasSize,
                    originalUserId: userId,
                    stroke: stroke // Cache the stroke
                )
                
                allKnownStrokes[strokeId] = strokeInfo
                strokeOrder.append(strokeId)
                
                // Send to Firebase
                firebaseManager.sendStroke(
                    strokeData: strokeData,
                    strokeId: strokeId,
                    userId: userId,
                    canvasSize: currentCanvasSize
                )
                
                // Self-echo: If echo mode is enabled, create echo copies with offset
                if echoModeEnabled {
                    let echoLimit = echoCount == 0 ? 10 : echoCount // Cap infinite at 10 for safety
                    for echoIndex in 1...echoLimit {
                        let echoId = UUID().uuidString
                        
                        // Create offset echo stroke
                        let offset = CGFloat(echoIndex) * 8.0 // 8pt offset per echo
                        var echoStroke = stroke
                        echoStroke.transform = echoStroke.transform.translatedBy(x: offset, y: offset)
                        
                        // Serialize the offset stroke
                        var echoDrawing = PKDrawing()
                        echoDrawing.strokes = [echoStroke]
                        let echoData = echoDrawing.dataRepresentation()
                        
                        let echoStrokeInfo = StrokeInfo(
                            id: echoId,
                            data: echoData,
                            timestamp: timestamp + Double(index) * 0.001 + Double(echoIndex) * 0.0001,
                            originalSize: currentCanvasSize,
                            originalUserId: userId,
                            stroke: echoStroke
                        )
                        allKnownStrokes[echoId] = echoStrokeInfo
                        strokeOrder.append(echoId)
                        
                        // CRITICAL: Send echo to Firebase so other users see it!
                        firebaseManager.sendStroke(
                            strokeData: echoData,
                            strokeId: echoId,
                            userId: userId,
                            canvasSize: currentCanvasSize
                        )
                        
                        // Log the echo
                        diagnostics.logEcho(strokeId: echoId, originalStrokeId: strokeId, count: echoIndex)
                    }
                }
            }
            
            // If we added echo strokes, rebuild canvas to show them
            if echoModeEnabled {
                rebuildCanvas()
            }
            
            lastCanvasStrokeCount = currentStrokes.count
            
        } else if currentStrokes.count < lastCanvasStrokeCount {
            // Canvas was cleared or strokes removed
            diagnostics.logWarning("Canvas stroke count decreased: \(lastCanvasStrokeCount) → \(currentStrokes.count)")
            lastCanvasStrokeCount = currentStrokes.count
        }
    }
    
    // Rebuild canvas from all known strokes (reconciliation)
    private func rebuildCanvas() {
        guard !isRebuilding else {
            diagnostics.logWarning("Already rebuilding, skipping")
            return
        }
        
        // CRITICAL: If user is actively drawing, defer the rebuild
        if isUserDrawing {
            diagnostics.logRebuild(strokeCount: allKnownStrokes.count, deferred: true)
            needsRebuild = true
            return
        }
        
        isRebuilding = true
        isReceivingUpdate = true
        diagnostics.updateMetrics(roomCode: nil as String?, userId: nil as String?, isRebuilding: true)
        
        diagnostics.logRebuild(strokeCount: allKnownStrokes.count, deferred: false)
        
        DispatchQueue.main.async {
            var newDrawing = PKDrawing()
            
            // Build canvas from all strokes in timestamp order
            for strokeId in self.strokeOrder {
                guard var strokeInfo = self.allKnownStrokes[strokeId] else { continue }
                
                // Use cached stroke if available, otherwise decode
                let strokes: [PKStroke]
                if let cachedStroke = strokeInfo.stroke {
                    strokes = [cachedStroke]
                } else if let drawing = try? PKDrawing(data: strokeInfo.data) {
                    // Scale if needed
                    var scaledDrawing = drawing
                    let needsScaling = (strokeInfo.originalSize != nil &&
                                       self.currentCanvasSize.width > 0 && self.currentCanvasSize.height > 0 &&
                                       strokeInfo.originalSize!.width > 0 && strokeInfo.originalSize!.height > 0 &&
                                       strokeInfo.originalSize! != self.currentCanvasSize)
                    
                    if needsScaling, let originalSize = strokeInfo.originalSize {
                        scaledDrawing = self.scaleDrawing(drawing, from: originalSize, to: self.currentCanvasSize)
                    }
                    
                    strokes = scaledDrawing.strokes
                    
                    // Cache the scaled stroke
                    if let firstStroke = strokes.first {
                        strokeInfo.stroke = firstStroke
                        self.allKnownStrokes[strokeId] = strokeInfo
                    }
                } else {
                    // Failed to decode - skip this stroke
                    continue
                }
                
                newDrawing.strokes.append(contentsOf: strokes)
            }
            
            // Apply the rebuilt drawing
            self.canvasView.drawing = newDrawing
            self.lastCanvasStrokeCount = newDrawing.strokes.count
            
            self.isReceivingUpdate = false
            self.isRebuilding = false
            self.diagnostics.updateMetrics(roomCode: nil, userId: nil, isRebuilding: false)
        }
    }
    
    // Handle echo mode for a received stroke
    private func handleEcho(strokeId: String, strokeInfo: StrokeInfo) {
        let currentCount = strokeEchoCounts[strokeId, default: 0]
        
        // Check if we've hit the echo limit
        if echoCount > 0 && currentCount >= echoCount {
            echoedStrokeIds.insert(strokeId)
            diagnostics.logInfo("Echo limit reached for stroke \(strokeId.prefix(8))")
            return
        }
        
        // Generate new stroke ID for the echo
        let echoStrokeId = UUID().uuidString
        let timestamp = Date().timeIntervalSince1970
        
        diagnostics.logEcho(strokeId: echoStrokeId, originalStrokeId: strokeId, count: currentCount + 1)
        
        // CRITICAL FIX: Add echoed stroke to local collection IMMEDIATELY
        // This prevents waiting for Firebase round-trip and ensures smooth echo effect
        let echoStrokeInfo = StrokeInfo(
            id: echoStrokeId,
            data: strokeInfo.data,
            timestamp: timestamp,
            originalSize: strokeInfo.originalSize,
            originalUserId: strokeInfo.originalUserId,
            stroke: strokeInfo.stroke // Use cached stroke if available
        )
        
        allKnownStrokes[echoStrokeId] = echoStrokeInfo
        strokeOrder.append(echoStrokeId)
        strokeOrder.sort { id1, id2 in
            let t1 = allKnownStrokes[id1]?.timestamp ?? 0
            let t2 = allKnownStrokes[id2]?.timestamp ?? 0
            return t1 < t2
        }
        
        // Send to Firebase so other devices receive it
        firebaseManager.sendStroke(
            strokeData: strokeInfo.data,
            strokeId: echoStrokeId,
            userId: userId,
            canvasSize: strokeInfo.originalSize ?? currentCanvasSize,
            originalUserId: strokeInfo.originalUserId
        )
        
        // Rebuild canvas to show the echo immediately
        rebuildCanvas()
        
        // Mark as echoed
        echoedStrokeIds.insert(strokeId)
        if echoCount > 0 {
            strokeEchoCounts[strokeId, default: 0] += 1
        }
        
    }
    
    // Log echo state change
    func logEchoStateChange() {
        diagnostics.logEchoStateChange(enabled: echoModeEnabled, count: echoCount)
        
        // Initialize the tracking counter when echo is enabled
        if echoModeEnabled {
            echoEnabledStrokeCount = canvasView.drawing.strokes.count
            diagnostics.logInfo("Echo tracking initialized at \(echoEnabledStrokeCount) strokes")
        }
    }
    
    // Reset stroke tracking (for canvas clear)
    func resetStrokeTracking() {
        allKnownStrokes.removeAll()
        strokeOrder.removeAll()
        lastCanvasStrokeCount = 0
        echoedStrokeIds.removeAll()
        strokeEchoCounts.removeAll()
        print("🧹 Stroke tracking reset")
    }
    
    // MARK: - Common
    
    func handleDrawingStarted() {
        isUserDrawing = true
        markActivity() // Resume sync timer on user activity
        diagnostics.logUserDrawing(started: true)
    }
    
    func handleDrawingEnded() {
        isUserDrawing = false
        diagnostics.logUserDrawing(started: false)
        
        // Always wait a bit for PKCanvasView to update, then check if we need to rebuild
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
            guard let self = self else { return }
            
            // Post-drawing check
            
            // For SIMULTANEOUS mode: use stroke-by-stroke system
            if self.roomMode != "turnBased" {
                // First, capture any local strokes
                self.captureNewLocalStrokes()
                
                // Then, if there was a deferred rebuild OR if new strokes arrived during the 50ms wait, rebuild now
                if self.needsRebuild {
                    self.diagnostics.logInfo("Executing deferred rebuild")
                    self.needsRebuild = false
                    self.rebuildCanvas()
                }
            } else {
                // For TURN-BASED mode: add echoes directly to canvas
                self.addEchoesToCanvas()
            }
        }
    }
    
    // Add echo strokes directly to canvas (for turn-based mode)
    private func addEchoesToCanvas() {
        guard echoModeEnabled else {
            // Update the tracking counter even when echo is off
            echoEnabledStrokeCount = canvasView.drawing.strokes.count
            return
        }
        
        let currentDrawing = canvasView.drawing
        let currentCount = currentDrawing.strokes.count
        
        // Only echo strokes drawn AFTER echo was enabled
        guard currentCount > echoEnabledStrokeCount else { return }
        
        // Get only the NEW strokes since echo was enabled
        let newCount = currentCount - echoEnabledStrokeCount
        let newStrokes = Array(currentDrawing.strokes.suffix(newCount))
        
        var drawing = currentDrawing
        let echoLimit = echoCount == 0 ? 10 : echoCount
        
        for stroke in newStrokes {
            for echoIndex in 1...echoLimit {
                // Create offset echo stroke
                let offset = CGFloat(echoIndex) * 8.0
                var echoStroke = stroke
                echoStroke.transform = echoStroke.transform.translatedBy(x: offset, y: offset)
                
                // Add to drawing
                drawing.strokes.append(echoStroke)
                
                diagnostics.logEcho(strokeId: "TB-\(UUID().uuidString.prefix(8))", 
                                  originalStrokeId: "original", 
                                  count: echoIndex)
            }
        }
        
        // Update canvas with echoed strokes
        canvasView.drawing = drawing
        
        // Update the tracking counter to include the new echoed strokes
        echoEnabledStrokeCount = drawing.strokes.count
    }
    
    func handleDrawingChange(_ drawing: PKDrawing) {
        // Mode-specific syncing happens in timers
        print("✏️ Drawing changed: \(drawing.strokes.count) strokes, isMyTurn=\(isMyTurn), isReceiving=\(isReceivingUpdate)")
    }
    
    func setColor(_ color: Color) {
        let uiColor = UIColor(color)
        canvasView.tool = PKInkingTool(.pen, color: uiColor, width: 3)
    }
    
    func loadDrawing(_ drawing: PKDrawing) {
        canvasView.drawing = drawing
        lastLocalDrawing = drawing.dataRepresentation()
    }
    
    func passTurnToNext() {
        guard roomMode == "turnBased" else { return }
        
        // Get all users and pass turn to next one
        firebaseManager.getUsersInRoom { [weak self] (userIds: [String]) in
            guard let self = self else { return }
            
            // Filter out current user
            let otherUsers = userIds.filter { $0 != self.userId }
            
            if let nextUser = otherUsers.first {
                self.firebaseManager.passTurn(toUserId: nextUser)
            }
        }
    }
    
    deinit {
        syncTimer?.invalidate()
    }
}

// MARK: - Color Options

struct ColorOption: Hashable {
    let color: Color
    
    static let allColors: [ColorOption] = [
        ColorOption(color: .black),
        ColorOption(color: .red),
        ColorOption(color: .blue),
        ColorOption(color: .green),
        ColorOption(color: .yellow),
        ColorOption(color: .orange),
        ColorOption(color: .purple),
        ColorOption(color: .pink),
        ColorOption(color: .brown),
        ColorOption(color: .gray),
        ColorOption(color: .cyan),
        ColorOption(color: .mint)
    ]
}

// MARK: - Extensions

extension UIColor {
    func toHex() -> String {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        
        getRed(&r, green: &g, blue: &b, alpha: &a)
        
        return String(format: "#%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
    }
    
    convenience init?(hex: String) {
        let r, g, b: CGFloat
        
        if hex.hasPrefix("#") {
            let start = hex.index(hex.startIndex, offsetBy: 1)
            let hexColor = String(hex[start...])
            
            if hexColor.count == 6 {
                let scanner = Scanner(string: hexColor)
                var hexNumber: UInt64 = 0
                
                if scanner.scanHexInt64(&hexNumber) {
                    r = CGFloat((hexNumber & 0xff0000) >> 16) / 255
                    g = CGFloat((hexNumber & 0x00ff00) >> 8) / 255
                    b = CGFloat(hexNumber & 0x0000ff) / 255
                    
                    self.init(red: r, green: g, blue: b, alpha: 1.0)
                    return
                }
            }
        }
        
        return nil
    }
}

// MARK: - Tool Button

private struct ToolButton: View {
    let icon: String
    let isActive: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
                .padding(8)
                .background(isActive ? Color.blue : Color.gray)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    DrawingCanvasView()
}


