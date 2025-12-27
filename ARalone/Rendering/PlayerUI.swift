//
//  PlayerUI.swift
//  ARalone
//
//  Created by lukas on 27.12.25.
//

import UIKit

@MainActor
extension Player {
    var color: UIColor {
        switch self {
        case .red:  return .systemRed
        case .blue: return .systemBlue
        }
    }
}
