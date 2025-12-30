//
//  Player.swift
//  ARalone
//
//  Created by lukas on 17.12.25.
//
import SwiftUI

enum Player {
    case red
    case blue
}

extension Player {

    var uiColor: Color {
        switch self {
        case .red:
            return .red
        case .blue:
            return .blue
        }
    }

    var displayName: String {
        switch self {
        case .red:
            return "Red"
        case .blue:
            return "Blue"
        }
    }
}
