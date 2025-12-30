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
            var removedHex: HexCoordinate? = nil
            var movedDefender: (from: HexCoordinate, to: HexCoordinate, player: Player)? = nil
        }
    
    @Published var currentPlayer: Player = .red
    @Published var marbles: [MarbleModel] = []
    @Published var claimedHexes: [HexCoordinate: Player] = [:]
    var lastPushDelta: PushDelta? = nil
    

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
}
