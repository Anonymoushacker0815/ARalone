//
//  HexCoordinate.swift
//  ARalone
//
//  Created by lukas on 17.12.25.
//

struct HexCoordinate: Hashable {
    let q: Int
    let r: Int
}

extension HexCoordinate {
    init(_ tuple: (q: Int, r: Int)) {
        self.q = tuple.q
        self.r = tuple.r
    }
}
