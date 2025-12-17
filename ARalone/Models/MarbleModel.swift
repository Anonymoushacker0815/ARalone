//
//  MarbleModel.swift
//  ARalone
//
//  Created by lukas on 17.12.25.
//

import Foundation

struct MarbleModel: Identifiable {
    let id = UUID()
    let player: Player
    var hex: HexCoordinate
}
