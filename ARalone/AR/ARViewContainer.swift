//
//  ARViewContainer.swift
//  ARalone
//
//  Created by Lukas Eberhart on 12.11.25.
//

import SwiftUI
import RealityKit
import ARKit

struct ARViewContainer: UIViewRepresentable {
    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)

        // Configure AR session for horizontal plane detection
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal]
        config.environmentTexturing = .automatic
        if ARWorldTrackingConfiguration.supportsFrameSemantics(.personSegmentationWithDepth) {
            config.frameSemantics.insert(.personSegmentationWithDepth) // hands occlude board/pieces (optional)
        }
        arView.session.run(config)

        // Coaching overlay to guide plane discovery
        let coach = ARCoachingOverlayView()
        coach.goal = .horizontalPlane
        coach.session = arView.session
        coach.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        arView.addSubview(coach)

        // Tap-to-place handler
        let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        arView.addGestureRecognizer(tap)

        context.coordinator.arView = arView
        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {}

    final class Coordinator: NSObject {
        weak var arView: ARView?
        var boardAnchor: AnchorEntity?

        @objc func handleTap(_ recognizer: UITapGestureRecognizer) {
            guard let arView else { return }
            let location = recognizer.location(in: arView)

            // Raycast to a detected or estimated horizontal plane
            guard let result = arView.raycast(from: location, allowing: .estimatedPlane, alignment: .horizontal).first else {
                return
            }

            // Remove previous board (re-place)
            boardAnchor?.removeFromParent()

            // Build & place a flat hex-board
            let config = BoardConfig()
            let anchor = BoardRenderer.makeBoardAnchor(at: result.worldTransform, config: config)

            arView.scene.addAnchor(anchor)
            boardAnchor = anchor
        }
    }
}
