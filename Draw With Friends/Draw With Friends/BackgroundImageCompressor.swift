//
//  BackgroundImageCompressor.swift
//  Draw With Friends
//

import UIKit

enum BackgroundImageCompressor {
    static let maxDimension: CGFloat = 1024
    static let maxBytes = 250_000
    
    /// Downscale then JPEG-compress so Realtime Database never stores a camera original.
    static func compressedData(from image: UIImage) -> Data? {
        let resized = resizedImage(image, maxDimension: maxDimension)
        var quality: CGFloat = 0.5
        var data = resized.jpegData(compressionQuality: quality)
        
        while let current = data, current.count > maxBytes, quality > 0.22 {
            quality -= 0.08
            data = resized.jpegData(compressionQuality: quality)
        }
        
        guard let data, data.count <= maxBytes else { return nil }
        return data
    }
    
    private static func resizedImage(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        let longest = max(size.width, size.height)
        guard longest > maxDimension, longest > 0 else { return image }
        
        let scale = maxDimension / longest
        let newSize = CGSize(width: floor(size.width * scale), height: floor(size.height * scale))
        guard newSize.width > 0, newSize.height > 0 else { return image }
        
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
        return renderer.image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: newSize))
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
