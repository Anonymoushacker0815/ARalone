//
//  GameState.swift
//  ARalone
//
//  Created by lukas on 17.12.25.
//

final class GameState {

    var currentPlayer: Player = .red
    var marbles: [MarbleModel] = []
    var claimedHexes: [HexCoordinate: Player] = [:]

    func marble(at hex: HexCoordinate) -> MarbleModel? {
        marbles.first { $0.hex == hex }
    }

    func isHexEmpty(_ hex: HexCoordinate) -> Bool {
        marble(at: hex) == nil
    }
    
    func claimHex(_ hex: HexCoordinate, for player: Player) {
            claimedHexes[hex] = player
        }
    
    func switchTurn() {
        currentPlayer = (currentPlayer == .red) ? .blue : .red
    }
}
