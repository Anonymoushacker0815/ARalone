//
//  Movement.swift
//  ARalone
//
//  Created by lukas on 27.12.25.
//
import Foundation
enum MoveResult {
    case success(from: HexCoordinate, to: HexCoordinate, player: Player)
    case invalid
}

extension GameState {

    func moveMarble(
        at index: Int,
        to target: HexCoordinate,
        config: BoardConfig
    ) -> Bool {

        guard marbles.indices.contains(index) else { return false }

        let from = marbles[index].hex
        let movingPlayer = marbles[index].player

        // 1. Must be current player's marble
        guard movingPlayer == currentPlayer else { return false }

        // 2. Target must be empty
        guard isHexEmpty(target) else { return false }

        // 3. Must be valid & adjacent
        guard BoardRenderer.isValidHex(q: target.q, r: target.r, config: config) else { return false }

        guard BoardRenderer.isNeighbor(
            from: (from.q, from.r),
            to: (target.q, target.r)
        ) else { return false }

        // 4. Claim the hex we are leaving (only once)
        if claimedHexes[from] == nil {
            claimedHexes[from] = currentPlayer
        }

        // 5. Move marble (NOW this is legal)
        marbles[index].hex = target

        // 6. Switch turn
        switchTurn()

        return true
    }
}
