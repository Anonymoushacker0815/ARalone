//
//  HapticManager.swift
//  ARalone
//
//  Created by Lukas on 01.01.26.
//

import UIKit

enum HapticType {
    case light
    case medium
    case heavy
    case success
    case error
}

final class HapticManager {

    static let shared = HapticManager()

    private init() {}

    func trigger(_ type: HapticType) {
        DispatchQueue.main.async {
            switch type {
            case .light:
                UIImpactFeedbackGenerator(style: .light).impactOccurred()

            case .medium:
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()

            case .heavy:
                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()

            case .success:
                UINotificationFeedbackGenerator().notificationOccurred(.success)

            case .error:
                UINotificationFeedbackGenerator().notificationOccurred(.error)
            }
        }
    }
}
