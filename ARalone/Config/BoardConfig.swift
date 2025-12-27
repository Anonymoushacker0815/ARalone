//
//  BoardConfig.swift
//  ARalone
//
//  Created by Lukas Eberhart on 12.11.25.
//

import Foundation
import UIKit

struct BoardConfig {
    // Physical size of the board in meters (edge-to-edge square plane)
    var boardSizeMeters: Float = 0.5

    // Hex grid parameters
    var hexRadiusCells: Int = 4   // axial radius (R=4 -> 9 hexes across center row)
    var hexPixelRadius: CGFloat = 100  // hex corner-to-center distance in pixels (for texture generation)
    var lineWidth: CGFloat = 3.0
    var textureSize: Int = 2048   // final square texture resolution
    var drawOuterBorder: Bool = true
    // Marbles
    var marbleToHexScale: Float = 0.90
}

