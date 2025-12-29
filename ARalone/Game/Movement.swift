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
        lastPushDelta = nil
        
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

        // Reset delta for this attempt
        lastPushDelta = nil

        let attacker = marbles[attackerIndex]
        let defender = marbles[defenderIndex]

        // Must be opposing players
        guard attacker.player != defender.player else { return false }

        // Determine push direction (attacker -> defender)
        guard let direction = HexDirection.fromMove(
            from: attacker.hex,
            to: defender.hex
        ) else { return false }

        // Direction from defender back toward attacker
        let opposite = HexDirection.fromMove(
            from: defender.hex,
            to: attacker.hex
        )!

        // Strength checks (your current rules)
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

        func step(_ hex: HexCoordinate, _ dir: HexDirection) -> HexCoordinate {
            HexCoordinate(q: hex.q + dir.dq, r: hex.r + dir.dr)
        }

        // Find nearest allied marble of DEFENDER in front of defender (push direction)
        var cursor = defender.hex
        var foundBlockingAllyHex: HexCoordinate? = nil

        while true {
            let next = step(cursor, direction)

            // If next is off-board, stop scanning (no blocker found)
            if !BoardRenderer.isValidHex(q: next.q, r: next.r, config: config) {
                break
            }

            if let m = marble(at: next), m.player == defender.player {
                foundBlockingAllyHex = next
                break
            }

            cursor = next
        }

        // If we found an allied blocker:
        if let allyHex = foundBlockingAllyHex {
            let adjacentHex = step(defender.hex, direction)

            // If ally is immediately behind defender (adjacent in push direction) -> illegal push
            if allyHex == adjacentHex {
                return false // attacker retries; no turn switch
            }

            // Otherwise defender "rolls" and stops before the allied marble
            let stopHex = HexCoordinate(q: allyHex.q - direction.dq,
                                       r: allyHex.r - direction.dr)

            // (stopHex should always be valid here, but guard anyway)
            guard BoardRenderer.isValidHex(q: stopHex.q, r: stopHex.r, config: config) else {
                return false
            }

            // Move defender to stopHex (instead of removing)
            marbles[defenderIndex].hex = stopHex

            // Record delta for AR update
            lastPushDelta = PushDelta(
                removedHex: nil,
                movedDefender: (from: defender.hex, to: stopHex, player: defender.player)
            )

            // Move attacker into target
            marbles[attackerIndex].hex = target
            claimedHexes[target] = attacker.player

            // Color the defender landing hex too (per your rule)
            claimedHexes[stopHex] = defender.player

            switchTurn()
            return true
        }

        // Otherwise: no allied blocker found -> defender is pushed off-board (removed)
        // This matches your current behavior.
        marbles.remove(at: defenderIndex)

        // Adjust attacker index if needed
        let adjustedAttackerIndex =
            defenderIndex < attackerIndex ? attackerIndex - 1 : attackerIndex

        // Move attacker into target
        marbles[adjustedAttackerIndex].hex = target
        claimedHexes[target] = attacker.player

        // Record delta for AR update
        lastPushDelta = PushDelta(
            removedHex: defender.hex,
            movedDefender: nil
        )

        switchTurn()
        return true
    }
}
