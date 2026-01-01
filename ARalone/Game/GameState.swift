//
//  GameState.swift
//  ARalone
//
//  Created by lukas on 17.12.25.
//
import Foundation
import Combine

final class GameState: ObservableObject {
    
    struct PushDelta {
        var movedMarble: (from: HexCoordinate, to: HexCoordinate, player: Player)
        var removedMarble: (hex: HexCoordinate, player: Player)?
        var movedDefender: (from: HexCoordinate, to: HexCoordinate, player: Player)?
        var previousClaimedHexes: [HexCoordinate: Player]
    }

    @Published var currentPlayer: Player = .red
    @Published var marbles: [MarbleModel] = []
    @Published var claimedHexes: [HexCoordinate: Player] = [:]
    @Published var redCaptured: Int = 0
    @Published var blueCaptured: Int = 0

    var lastPushDelta: PushDelta? = nil
    
    var hasStarted: Bool {
        !marbles.isEmpty
    }
    
    var winner: Player? {
        if redCaptured >= 3 { return .red }
        if blueCaptured >= 3 { return .blue }
        return nil
    }

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
    func countOwnedHexes(
        from start: HexCoordinate,
        direction: HexDirection,
        owner: Player
    ) -> Int {

        var count = 0
        var current = HexCoordinate(
            q: start.q + direction.dq,
            r: start.r + direction.dr
        )

        while claimedHexes[current] == owner {
            count += 1
            current = HexCoordinate(
                q: current.q + direction.dq,
                r: current.r + direction.dr
            )
        }

        return count
    }
    func undoLastMove() {
        guard let delta = lastPushDelta else { return }

        // 1️⃣ Restore claimed hex colors
        claimedHexes = delta.previousClaimedHexes

        // 2️⃣ Move attacker marble back
        if let idx = marbles.firstIndex(where: {
            $0.hex == delta.movedMarble.to &&
            $0.player == delta.movedMarble.player
        }) {
            marbles[idx].hex = delta.movedMarble.from
        }

        // 3️⃣ Restore defender if it was pushed off board
        if let removed = delta.removedMarble {
            marbles.append(
                MarbleModel(
                    player: removed.player,
                    hex: removed.hex
                )
            )
        }

        // 4️⃣ Restore defender if it was moved (blocker case)
        if let moved = delta.movedDefender {
            if let idx = marbles.firstIndex(where: {
                $0.hex == moved.to &&
                $0.player == moved.player
            }) {
                marbles[idx].hex = moved.from
            }
        }

        // 5️⃣ Switch turn back
        switchTurn()

        // 6️⃣ Clear undo state (single-step undo)
        lastPushDelta = nil
    }
}
