//
//  SavedDrawingsView.swift
//  Draw With Friends
//
//  Created by Jamie on 10/11/2025.
//

import SwiftUI
import PencilKit

struct SavedDrawingsView: View {
    @StateObject private var drawingManager = DrawingManager.shared
    @Environment(\.dismiss) var dismiss
    var onLoadDrawing: (PKDrawing) -> Void
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.blue.opacity(0.05)
                    .ignoresSafeArea()
                
                if drawingManager.savedDrawings.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "folder")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("No saved drawings yet")
                            .font(.title2)
                            .foregroundColor(.gray)
                        Text("Save drawings from the canvas to see them here")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                } else {
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 16) {
                            ForEach(drawingManager.savedDrawings) { drawing in
                                DrawingThumbnailView(
                                    drawing: drawing,
                                    onLoad: {
                                        if let loadedDrawing = drawingManager.loadDrawing(id: drawing.id) {
                                            onLoadDrawing(loadedDrawing)
                                            dismiss()
                                        }
                                    },
                                    onDelete: {
                                        drawingManager.deleteDrawing(id: drawing.id)
                                    }
                                )
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("My Drawings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct DrawingThumbnailView: View {
    let drawing: SavedDrawing
    let onLoad: () -> Void
    let onDelete: () -> Void
    @State private var showDeleteAlert = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Thumbnail placeholder
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .shadow(radius: 2)
                
                Image(systemName: "scribble")
                    .font(.system(size: 40))
                    .foregroundColor(.blue.opacity(0.3))
            }
            .frame(height: 150)
            .onTapGesture {
                onLoad()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(drawing.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                Text(drawing.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            
            HStack {
                Button(action: onLoad) {
                    Label("Load", systemImage: "arrow.down.circle")
                        .font(.caption)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                
                Spacer()
                
                Button(action: { showDeleteAlert = true }) {
                    Image(systemName: "trash")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
        }
        .padding(8)
        .background(Color.white.opacity(0.8))
        .cornerRadius(12)
        .alert("Delete Drawing?", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                onDelete()
            }
        } message: {
            Text("This cannot be undone.")
        }
    }
}

#Preview {
    SavedDrawingsView(onLoadDrawing: { _ in })
}


