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

// Stores the marble's current hex coordinates
struct MarbleComponent: Component {
    var q: Int
    var r: Int
}

enum BoardRenderer {
    
    static func makeBoardEntity(config: BoardConfig) -> ModelEntity {
        let img = BoardTextureHex.makeHexBoardImage(
            config: config,
            claimedHexes: [:]
        )
        var material = UnlitMaterial()

        if let cg = img.cgImage,
           let tex = try? TextureResource(
            image: cg,
            options: .init(semantic: .color)
           ) {
            material.baseColor = .texture(tex)
        } else {
            material.baseColor = .color(.init(.white))
        }

        let mesh = MeshResource.generatePlane(
            width: config.boardSizeMeters,
            depth: config.boardSizeMeters
        )

        let board = ModelEntity(mesh: mesh, materials: [material])
        board.generateCollisionShapes(recursive: false)
        board.position.y = 0.001
        return board
    }


    // MARK: - Marble creation & sizing

    static func marbleRadiusMeters(config: BoardConfig) -> Float {
        let metersPerPixel = config.boardSizeMeters / Float(config.textureSize)
        let hexFlatToFlat_px = Float(config.hexPixelRadius) * sqrtf(3)
        let marbleDiameter_m = hexFlatToFlat_px * metersPerPixel * config.marbleToHexScale
        return marbleDiameter_m / 2
    }

    private static func makeMarbleEntity(config: BoardConfig,
                                         q: Int,
                                         r: Int) -> ModelEntity {
        let radius = marbleRadiusMeters(config: config)
        let sphere = MeshResource.generateSphere(radius: radius)

        var mat = SimpleMaterial()
        mat.baseColor = .color(.init(.blue))   // 👈 blue by default
        mat.roughness = 0.15

        let marble = ModelEntity(mesh: sphere, materials: [mat])
        marble.generateCollisionShapes(recursive: false)
        marble.components.set(MarbleComponent(q: q, r: r))
        return marble
    }
    
    static func spawnMarble(
        model: MarbleModel,
        config: BoardConfig,
        parent: Entity
    ) -> ModelEntity {

        let marble = MarbleFactory.makeMarble(
            model: model,
            config: config
        )

        let centerXZ = hexCenterLocalXZ(
            q: model.hex.q,
            r: model.hex.r,
            config: config
        )

        let radius = marbleRadiusMeters(config: config)

        marble.position = SIMD3<Float>(
            centerXZ.x,
            radius + 0.001,
            centerXZ.y
        )

        parent.addChild(marble)
        return marble
    }


    // MARK: - Hex coord → local board position (x,z)

    static func hexCenterLocalXZ(q: Int,
                                 r: Int,
                                 config: BoardConfig) -> SIMD2<Float> {
        let texSize = CGFloat(config.textureSize)
        let a = config.hexPixelRadius
        let R = config.hexRadiusCells

        func axialToPixel(_ q: Int, _ r: Int) -> CGPoint {
            let qf = CGFloat(q), rf = CGFloat(r)
            let x = a * sqrt(3) * (qf + rf/2.0)
            let y = a * 1.5 * rf
            return CGPoint(x: x, y: y)
        }

        // centers of all hexes to compute centering offset
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

        let offset = CGPoint(
            x: (texSize - contentW)/2.0 - minX,
            y: (texSize - contentH)/2.0 - minY
        )

        let p = axialToPixel(q, r)
        let centered = CGPoint(x: p.x + offset.x, y: p.y + offset.y)

        // map texture (0..texSize) → board (-boardSize/2 .. +boardSize/2)
        let nx = (centered.x / texSize) - 0.5
        let nz = (centered.y / texSize) - 0.5

        let xMeters = Float(nx) * config.boardSizeMeters
        let zMeters = Float(nz) * config.boardSizeMeters

        return SIMD2<Float>(xMeters, zMeters)
    }

    // MARK: - local (x,z) → nearest hex axial (q,r)

    static func localPositionToHex(x: Float,
                                   z: Float,
                                   config: BoardConfig) -> (q: Int, r: Int) {
        let metersPerPixel = config.boardSizeMeters / Float(config.textureSize)
        let aMeters = metersPerPixel * Float(config.hexPixelRadius)

        // continuous axial coords (see redblobgames)
        let qf = (sqrtf(3) / 3 * x - 1.0 / 3 * z) / aMeters
        let rf = (2.0 / 3 * z) / aMeters

        // cube coords for rounding
        let xf = qf
        let zf = rf
        let yf = -xf - zf

        var rx = roundf(xf)
        var ry = roundf(yf)
        var rz = roundf(zf)

        let xDiff = fabsf(rx - xf)
        let yDiff = fabsf(ry - yf)
        let zDiff = fabsf(rz - zf)

        if xDiff > yDiff && xDiff > zDiff {
            rx = -ry - rz
        } else if yDiff > zDiff {
            ry = -rx - rz
        } else {
            rz = -rx - ry
        }

        let q = Int(rx)
        let r = Int(rz)
        return (q, r)
    }

    static func isValidHex(q: Int, r: Int, config: BoardConfig) -> Bool {
        let R = config.hexRadiusCells
        let s = -q - r
        return abs(q) <= R && abs(r) <= R && abs(s) <= R
    }

    static func isNeighbor(from: (Int, Int), to: (Int, Int)) -> Bool {
        let (q0, r0) = from
        let (q1, r1) = to
        let dq = q1 - q0
        let dr = r1 - r0
        let ds = -(dq + dr)
        let dist = max(abs(dq), max(abs(dr), abs(ds)))
        return dist == 1
    }
}
func isEdgeHex(q: Int, r: Int, config: BoardConfig) -> Bool {
    let R = config.hexRadiusCells
    let s = -q - r
    return abs(q) == R || abs(r) == R || abs(s) == R
}
func edgeHexes(config: BoardConfig) -> [HexCoordinate] {
    let R = config.hexRadiusCells
    var result: [HexCoordinate] = []

    for q in -R...R {
        let r1 = max(-R, -q - R)
        let r2 = min(R, -q + R)
        for r in r1...r2 {
            if isEdgeHex(q: q, r: r, config: config) {
                result.append(HexCoordinate(q: q, r: r))
            }
        }
    }

    return result
}
func startingHexes(
    for player: Player,
    config: BoardConfig
) -> [HexCoordinate] {

    let edges = edgeHexes(config: config)

    let sortedByZ = edges.sorted {
        let z0 = BoardRenderer.hexCenterLocalXZ(q: $0.q, r: $0.r, config: config).y
        let z1 = BoardRenderer.hexCenterLocalXZ(q: $1.q, r: $1.r, config: config).y
        return z0 < z1
    }

    if player == .blue {
        // bottom edge → lowest Z
        return Array(sortedByZ.prefix(5))
    } else {
        // top edge → highest Z
        return Array(sortedByZ.suffix(5))
    }
}


func angleForHex(
    _ hex: HexCoordinate,
    config: BoardConfig
) -> Float {

    let pos = BoardRenderer.hexCenterLocalXZ(
        q: hex.q,
        r: hex.r,
        config: config
    )

    return atan2(pos.y, pos.x) // angle around center
}
func edgeHexesSorted(config: BoardConfig) -> [HexCoordinate] {
    let edges = edgeHexes(config: config)

    return edges.sorted {
        angleForHex($0, config: config) <
        angleForHex($1, config: config)
    }
}
