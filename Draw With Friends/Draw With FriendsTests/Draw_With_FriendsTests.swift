//
//  Draw_With_FriendsTests.swift
//  Draw With FriendsTests
//
//  Created by Jamie on 09/11/2025.
//

import Testing
import PencilKit
import UIKit
@testable import Draw_With_Friends

struct Draw_With_FriendsTests {

    @Test func exportKeepsBlackInkInDarkMode() async throws {
        let ink = PKInk(.pen, color: .black)
        let points = (0..<8).map { index -> PKStrokePoint in
            let t = CGFloat(index)
            return PKStrokePoint(
                location: CGPoint(x: 20 + t * 8, y: 20 + t * 8),
                timeOffset: TimeInterval(index) * 0.01,
                size: CGSize(width: 12, height: 12),
                opacity: 1,
                force: 1,
                azimuth: 0,
                altitude: .pi / 2
            )
        }
        let path = PKStrokePath(controlPoints: points, creationDate: Date())
        var drawing = PKDrawing()
        drawing.strokes = [PKStroke(ink: ink, path: path)]

        var image: UIImage?
        UITraitCollection(userInterfaceStyle: .dark).performAsCurrent {
            image = DrawingManager.shared.exportAsImage(
                drawing,
                backgroundImage: nil,
                canvasSize: CGSize(width: 120, height: 120)
            )
        }

        let exported = try #require(image)
        #expect(containsDarkInk(exported))
    }

    private func containsDarkInk(_ image: UIImage) -> Bool {
        guard let cgImage = image.cgImage else { return false }
        let width = cgImage.width
        let height = cgImage.height
        guard width > 0, height > 0 else { return false }

        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(
            data: &pixels,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return false }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        let step = max(1, width / 40)
        for y in stride(from: 0, to: height, by: step) {
            for x in stride(from: 0, to: width, by: step) {
                let i = (y * width + x) * 4
                let r = pixels[i]
                let g = pixels[i + 1]
                let b = pixels[i + 2]
                if r < 80 && g < 80 && b < 80 {
                    return true
                }
            }
        }
        return false
    }
}
