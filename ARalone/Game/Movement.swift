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

        // 2. Must be valid & adjacent
        guard BoardRenderer.isValidHex(q: target.q, r: target.r, config: config) else { return false }

        guard BoardRenderer.isNeighbor(
            from: (from.q, from.r),
            to: (target.q, target.r)
        ) else { return false }

        // 3. Target occupied? → attempt push
        if let defenderIndex = marbles.firstIndex(where: { $0.hex == target }) {
            return attemptPush(
                attackerIndex: index,
                defenderIndex: defenderIndex,
                target: target,
                config: config
            )
        }

        // 4. Move marble
        marbles[index].hex = target

        // 5. Claim / recolor the hex we moved onto
        claimedHexes[target] = movingPlayer

        // 6. Switch turn
        switchTurn()

        return true
    }
    func attemptPush(
        attackerIndex: Int,
        defenderIndex: Int,
        target: HexCoordinate,
        config: BoardConfig
    ) -> Bool {

        let attacker = marbles[attackerIndex]
        let defender = marbles[defenderIndex]

        // Must be opposing players
        guard attacker.player != defender.player else { return false }

        // Determine push direction
        guard let direction = HexDirection.fromMove(
            from: attacker.hex,
            to: defender.hex
        ) else { return false }

        // Opposite direction (behind attacker)
        let opposite = HexDirection.fromMove(
            from: defender.hex,
            to: attacker.hex
        )!

        // Count strength
        let attackerStrength = countOwnedHexes(
            from: attacker.hex,
            direction: opposite,
            owner: attacker.player
        )

        let defenderStrength = countOwnedHexes(
            from: defender.hex,
            direction: direction,
            owner: defender.player
        )

        // Defender wins ties
        guard attackerStrength > defenderStrength else {
            return false
        }

        marbles.remove(at: defenderIndex)

        // Adjust attacker index if needed
        let adjustedAttackerIndex =
            defenderIndex < attackerIndex ? attackerIndex - 1 : attackerIndex

        // Move attacker
        marbles[adjustedAttackerIndex].hex = target

        // Claim / recolor the hex attacker moved onto
        claimedHexes[target] = attacker.player

        switchTurn()
        return true
    }
}
