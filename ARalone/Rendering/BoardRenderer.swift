//
//  BoardRenderer.swift
//  ARalone
//
//  Created by Lukas Eberhart on 12.11.25.
//

import Foundation
import RealityKit
import UIKit
import simd
import SwiftUI

struct MarbleComponent: Component {
    var q: Int
    var r: Int
}

enum BoardRenderer {
    static func makeBoardAnchor(at worldTransform: simd_float4x4,
                                config: BoardConfig) -> AnchorEntity {
        // Texture + material
        let img = BoardTextureHex.makeHexBoardImage(config: config)
        var material = UnlitMaterial()
        if let cg = img.cgImage,
           let tex = try? TextureResource(image: cg, options: .init(semantic: .color)) {
            material.baseColor = .texture(tex)
        } else {
            material.baseColor = .color(.init(.white))
        }

        // Flat plane
        let mesh = MeshResource.generatePlane(width: config.boardSizeMeters,
                                              depth: config.boardSizeMeters)
        let board = ModelEntity(mesh: mesh, materials: [material])
        board.generateCollisionShapes(recursive: false)
        board.position.y = 0.001   // tiny lift above detected plane

        // Anchor at raycast
        let anchor = AnchorEntity(world: worldTransform)
        anchor.addChild(board)

        // ----- MARBLE -----
        // create marble model
        let marble = makeMarbleEntity(config: config)

        // compute marble radius again to position it correctly on top
        let marbleRadius = marbleRadiusMeters(config: config)

        // choose which hex to use (axial coordinates q, r)
        // (0, 0) = center hex. Change this to e.g. (0, config.hexRadiusCells) for center of one edge.
        let centerHexQ = 0
        let centerHexR = 0

        let centerXZ = hexCenterLocalXZ(q: centerHexQ, r: centerHexR, config: config)

        marble.position = SIMD3<Float>(
            centerXZ.x,
            marbleRadius + 0.001,      // sits on top of the board
            centerXZ.y                  // use the second component as Z
        )

        anchor.addChild(marble)
        // -------------------

        return anchor
    }

    // MARK: - Marble creation & sizing

    private static func marbleRadiusMeters(config: BoardConfig) -> Float {
        // how many meters one texture pixel represents
        let metersPerPixel = config.boardSizeMeters / Float(config.textureSize)

        // hex flat-to-flat in pixels (pointy-top): √3 * a
        let hexFlatToFlat_px = Float(config.hexPixelRadius) * sqrtf(3)

        // target marble diameter slightly smaller than hex inner circle
        let marbleDiameter_m = hexFlatToFlat_px * metersPerPixel * config.marbleToHexScale
        return marbleDiameter_m / 2
    }

    private static func makeMarbleEntity(config: BoardConfig) -> ModelEntity {
        let radius = marbleRadiusMeters(config: config)

        // Sphere mesh
        let sphere = MeshResource.generateSphere(radius: radius)

        var mat = SimpleMaterial()
        mat.baseColor = .color(.init(.blue))
        mat.roughness = 0.15

        let marble = ModelEntity(mesh: sphere, materials: [mat])
        marble.generateCollisionShapes(recursive: false)
        return marble
    }

    // MARK: - Hex coord → local board position

    /// Returns the local (x, z) position on the board plane for a hex with axial coordinates (q, r).
    /// This mirrors the pointy-top axial layout used when drawing the texture.
    private static func hexCenterLocalXZ(q: Int, r: Int, config: BoardConfig) -> SIMD2<Float> {
        let a = config.hexPixelRadius            // hex size in *texture pixels*
        let R = config.hexRadiusCells
        let texSize = CGFloat(config.textureSize)

        // axial (q, r) -> pixel (x, y) in texture space, before centering
        func axialToPixel(_ q: Int, _ r: Int) -> CGPoint {
            let qf = CGFloat(q), rf = CGFloat(r)
            let x = a * sqrt(3) * (qf + rf/2.0)
            let y = a * 1.5 * rf
            return CGPoint(x: x, y: y)
        }

        // Compute bounds of all hex centers to know how to center them in the texture
        var centers: [CGPoint] = []
        for qVal in -R...R {
            let r1 = max(-R, -qVal - R)
            let r2 = min(R, -qVal + R)
            for rVal in r1...r2 {
                centers.append(axialToPixel(qVal, rVal))
            }
        }

        let minX = centers.map(\.x).min() ?? 0
        let maxX = centers.map(\.x).max() ?? 0
        let minY = centers.map(\.y).min() ?? 0
        let maxY = centers.map(\.y).max() ?? 0

        let contentW = maxX - minX
        let contentH = maxY - minY

        // same centering logic as texture: put the grid in the middle of the image
        let offset = CGPoint(
            x: (texSize - contentW)/2.0 - minX,
            y: (texSize - contentH)/2.0 - minY
        )

        // pixel position of this hex in the texture
        let p = axialToPixel(q, r)
        let centered = CGPoint(x: p.x + offset.x, y: p.y + offset.y)

        // convert texture pixels -> board local meters.
        // texture (0 .. texSize) maps to board (-boardSize/2 .. +boardSize/2)
        let nx = (centered.x / texSize) - 0.5      // -0.5 .. +0.5
        let nz = (centered.y / texSize) - 0.5

        let xMeters = Float(nx) * config.boardSizeMeters
        let zMeters = Float(nz) * config.boardSizeMeters

        return SIMD2<Float>(xMeters, zMeters)
    }
}
