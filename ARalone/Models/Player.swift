//
//  Player.swift
//  ARalone
//
//  Created by lukas on 17.12.25.
//
import UIKit

enum Player {
    case red
    case blue
}

extension Player {
    var color: UIColor {
        switch self {
        case .red:  return .systemRed
        case .blue: return .systemBlue
        }
    }
}
