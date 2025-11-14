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
    
    func exportAsImage(_ drawing: PKDrawing) -> UIImage? {
        let image = drawing.image(from: drawing.bounds, scale: UIScreen.main.scale)
        return image
    }
    
    func saveToPhotos(_ image: UIImage, completion: @escaping (Bool) -> Void) {
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        completion(true)
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

