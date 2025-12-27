//
//  HexDirection.swift
//  ARalone
//
//  Created by lukas on 27.12.25.
//

enum HexDirection: CaseIterable {
    case east, west
    case northeast, southwest
    case northwest, southeast

    var dq: Int {
        switch self {
        case .east: return 1
        case .west: return -1
        case .northeast: return 0
        case .southwest: return 0
        case .northwest: return -1
        case .southeast: return 1
        }
    }

    var dr: Int {
        switch self {
        case .east: return 0
        case .west: return 0
        case .northeast: return -1
        case .southwest: return 1
        case .northwest: return 1
        case .southeast: return -1
        }
    }

    static func fromMove(from: HexCoordinate, to: HexCoordinate) -> HexDirection? {
        let dq = to.q - from.q
        let dr = to.r - from.r

        return HexDirection.allCases.first {
            $0.dq == dq && $0.dr == dr
        }
    }
}
