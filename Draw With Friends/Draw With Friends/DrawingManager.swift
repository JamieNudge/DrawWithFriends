//
//  DrawingManager.swift
//  Draw With Friends
//
//  Created by Jamie on 10/11/2025.
//

import Foundation
import Combine
import PencilKit
import UIKit
import Photos

class DrawingManager: ObservableObject {
    static let shared = DrawingManager()
    
    @Published var savedDrawings: [SavedDrawing] = []
    
    private init() {
        loadDrawingsList()
    }
    
    // MARK: - Save Drawing
    
    func saveDrawing(_ drawing: PKDrawing, name: String? = nil) {
        let drawingName = name ?? "Drawing \(Date().formatted(date: .abbreviated, time: .shortened))"
        
        let savedDrawing = SavedDrawing(
            id: UUID(),
            name: drawingName,
            createdAt: Date(),
            drawing: drawing
        )
        
        // Save drawing data
        let data = drawing.dataRepresentation()
        let filename = "\(savedDrawing.id.uuidString).pkdrawing"
        let url = getDocumentsDirectory().appendingPathComponent(filename)
        try? data.write(to: url)
        
        // Add to list
        savedDrawings.insert(savedDrawing, at: 0)
        saveDrawingsList()
    }
    
    // MARK: - Load Drawing
    
    func loadDrawing(id: UUID) -> PKDrawing? {
        let filename = "\(id.uuidString).pkdrawing"
        let url = getDocumentsDirectory().appendingPathComponent(filename)
        
        guard let data = try? Data(contentsOf: url),
              let drawing = try? PKDrawing(data: data) else {
            return nil
        }
        
        return drawing
    }
    
    // MARK: - Delete Drawing
    
    func deleteDrawing(id: UUID) {
        // Delete file
        let filename = "\(id.uuidString).pkdrawing"
        let url = getDocumentsDirectory().appendingPathComponent(filename)
        try? FileManager.default.removeItem(at: url)
        
        // Remove from list
        savedDrawings.removeAll { $0.id == id }
        saveDrawingsList()
    }
    
    // MARK: - Export as Image
    
    func exportAsImage(_ drawing: PKDrawing, backgroundImage: UIImage?, canvasSize: CGSize) -> UIImage? {
        // Use canvas size if provided and valid, otherwise fall back to drawing bounds
        let imageSize: CGSize
        if canvasSize.width > 0 && canvasSize.height > 0 {
            imageSize = canvasSize
        } else if !drawing.bounds.isEmpty {
            let padding: CGFloat = 20
            imageSize = CGSize(
                width: drawing.bounds.width + padding * 2,
                height: drawing.bounds.height + padding * 2
            )
        } else {
            // No drawing and no canvas size
            return nil
        }
        
        // Create composite image
        let format = UIGraphicsImageRendererFormat()
        format.scale = UIScreen.main.scale
        format.opaque = true
        
        let renderer = UIGraphicsImageRenderer(size: imageSize, format: format)
        
        let image = renderer.image { context in
            // Fill with white background first
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: imageSize))
            
            // Draw background image if available
            if let backgroundImage = backgroundImage {
                backgroundImage.draw(in: CGRect(origin: .zero, size: imageSize))
            }
            
            // Draw the PencilKit drawing on top
            if !drawing.bounds.isEmpty {
                let drawingImage = drawing.image(from: drawing.bounds, scale: UIScreen.main.scale)
                drawingImage.draw(in: CGRect(origin: .zero, size: imageSize), blendMode: .normal, alpha: 1.0)
            }
        }
        
        return image
    }
    
    func saveToPhotos(_ image: UIImage, completion: @escaping (Bool) -> Void) {
        // Check authorization status first
        let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        
        switch status {
        case .authorized, .limited:
            // Already authorized, save the image
            performSave(image: image, completion: completion)
            
        case .notDetermined:
            // Request authorization
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { newStatus in
                DispatchQueue.main.async {
                    if newStatus == .authorized || newStatus == .limited {
                        self.performSave(image: image, completion: completion)
                    } else {
                        completion(false)
                    }
                }
            }
            
        default:
            // Denied or restricted
            completion(false)
        }
    }
    
    private func performSave(image: UIImage, completion: @escaping (Bool) -> Void) {
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAsset(from: image)
        }) { success, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Error saving to photos: \(error.localizedDescription)")
                    completion(false)
                } else {
                    print("✅ Successfully saved to photos")
                    completion(success)
                }
            }
        }
    }
    
    // MARK: - Private Helpers
    
    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    private func saveDrawingsList() {
        let list = savedDrawings.map { DrawingListItem(id: $0.id, name: $0.name, createdAt: $0.createdAt) }
        if let data = try? JSONEncoder().encode(list) {
            UserDefaults.standard.set(data, forKey: "savedDrawingsList")
        }
    }
    
    private func loadDrawingsList() {
        guard let data = UserDefaults.standard.data(forKey: "savedDrawingsList"),
              let list = try? JSONDecoder().decode([DrawingListItem].self, from: data) else {
            return
        }
        
        savedDrawings = list.map { SavedDrawing(id: $0.id, name: $0.name, createdAt: $0.createdAt, drawing: PKDrawing()) }
    }
}

// MARK: - Models

struct SavedDrawing: Identifiable {
    let id: UUID
    let name: String
    let createdAt: Date
    var drawing: PKDrawing
}

struct DrawingListItem: Codable {
    let id: UUID
    let name: String
    let createdAt: Date
}

