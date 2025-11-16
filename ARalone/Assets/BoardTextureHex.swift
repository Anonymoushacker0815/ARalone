//
//  BoardTextureHex.swift
//  ARalone
//
//  Created by Lukas Eberhart on 12.11.25.
//

import Foundation
import UIKit
import CoreGraphics

enum BoardTextureHex {

    /// Creates a square image with a centered hexagonal *board area*
    /// filled by white hex tiles outlined in black. Background is white,
    /// so it looks like white tiles with black borders (no color fill).
    static func makeHexBoardImage(config: BoardConfig) -> UIImage {
        let size = CGSize(width: config.textureSize, height: config.textureSize)
        let a = config.hexPixelRadius
        let R = config.hexRadiusCells
        let lineW = config.lineWidth

        func axialToPixel(q: Int, r: Int) -> CGPoint {
            let qf = CGFloat(q), rf = CGFloat(r)
            let x = a * sqrt(3) * (qf + rf/2.0)
            let y = a * 1.5 * rf
            return CGPoint(x: x, y: y)
        }

        // Collect every hex’s 6 corner points to get exact bounds
        var allCorners: [CGPoint] = []
        for q in -R...R {
            let r1 = max(-R, -q - R)
            let r2 = min(R, -q + R)
            for r in r1...r2 {
                let c = axialToPixel(q: q, r: r)
                // pointy-top hex corners (30° offset)
                for i in 0..<6 {
                    let angle = (.pi/6.0) + CGFloat(i) * (.pi/3.0)
                    let px = c.x + a * cos(angle)
                    let py = c.y + a * sin(angle)
                    allCorners.append(CGPoint(x: px, y: py))
                }
            }
        }

        // True tight bounds of the grid
        let minX = allCorners.map(\.x).min() ?? 0
        let maxX = allCorners.map(\.x).max() ?? 0
        let minY = allCorners.map(\.y).min() ?? 0
        let maxY = allCorners.map(\.y).max() ?? 0
        let contentW = maxX - minX
        let contentH = maxY - minY

        // Small visual margin around the grid (tweak if you want edge-to-edge)
        let margin: CGFloat = max(lineW * 2, a * 0.15)

        // Offset so the hex region is centered in the texture
        let offset = CGPoint(
            x: (size.width  - contentW)/2.0 - minX,
            y: (size.height - contentH)/2.0 - minY
        )

        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            // Background
            UIColor.white.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))

            UIColor.white.setFill()
            UIColor.black.setStroke()

            func hexPath(center: CGPoint, radius: CGFloat) -> UIBezierPath {
                let p = UIBezierPath()
                let angleOffset: CGFloat = .pi/6.0 // pointy-top
                for i in 0..<6 {
                    let ang = angleOffset + CGFloat(i) * (.pi / 3.0)
                    let x = center.x + radius * cos(ang)
                    let y = center.y + radius * sin(ang)
                    (i == 0) ? p.move(to: CGPoint(x: x, y: y))
                             : p.addLine(to: CGPoint(x: x, y: y))
                }
                p.close()
                return p
            }

            // Draw hexes, centered with a tiny margin by slightly shrinking radius
            let drawRadius = a - margin / max(contentW, contentH) * a
            for q in -R...R {
                let r1 = max(-R, -q - R)
                let r2 = min(R, -q + R)
                for r in r1...r2 {
                    let c = axialToPixel(q: q, r: r)
                    let center = CGPoint(x: c.x + offset.x, y: c.y + offset.y)
                    let path = hexPath(center: center, radius: drawRadius)
                    path.lineWidth = lineW
                    path.fill()
                    path.stroke()
                }
            }
        }
    }
}
