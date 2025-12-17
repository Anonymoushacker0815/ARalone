//
//  GameState.swift
//  ARalone
//
//  Created by lukas on 17.12.25.
//

final class GameState {

    var currentPlayer: Player = .red

    // Which hex is occupied by which marble
    var marbles: [MarbleModel] = []

    func marble(at hex: HexCoordinate) -> MarbleModel? {
        marbles.first { $0.hex == hex }
    }

    func isHexEmpty(_ hex: HexCoordinate) -> Bool {
        marble(at: hex) == nil
    }

    func switchTurn() {
        currentPlayer = (currentPlayer == .red) ? .blue : .red
    }
}
