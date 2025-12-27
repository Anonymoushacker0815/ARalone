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

        // AR session config
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal]
        config.environmentTexturing = .automatic

        // People occlusion (optional, looks nice if supported)
        if ARWorldTrackingConfiguration.supportsFrameSemantics(.personSegmentationWithDepth) {
            config.frameSemantics.insert(.personSegmentationWithDepth)
        }

        arView.session.run(config)

        // Coaching overlay to help find a plane
        let coach = ARCoachingOverlayView()
        coach.goal = .horizontalPlane
        coach.session = arView.session
        coach.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        arView.addSubview(coach)

        // Single tap gesture handles: place, select, move
        let tap = UITapGestureRecognizer(target: context.coordinator,
                                         action: #selector(Coordinator.handleTap(_:)))
        arView.addGestureRecognizer(tap)

        context.coordinator.arView = arView
        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {}

    final class Coordinator: NSObject {
        weak var arView: ARView?
        var boardAnchor: AnchorEntity?
        
        let gameState = GameState()

        // selection state
        var selectedMarble: ModelEntity?
        var originalMaterial: SimpleMaterial?

        func placeBoard(at screenPoint: CGPoint) {
            guard let arView else { return }

            guard let result = arView
                .raycast(from: screenPoint,
                         allowing: .existingPlaneGeometry,
                         alignment: .horizontal)
                .first
            else { return }

            let config = BoardConfig()
            let anchor = AnchorEntity(world: result.worldTransform)

            // 🔴 IMPORTANT: clear any previous state (safety)
            gameState.marbles.removeAll()
            gameState.claimedHexes.removeAll()
            gameState.currentPlayer = .red

            // Spawn red marbles
            for hex in startingHexes(for: .red, config: config) {
                let model = MarbleModel(player: .red, hex: hex)
                gameState.marbles.append(model)

                _ = BoardRenderer.spawnMarble(
                    model: model,
                    config: config,
                    parent: anchor
                )
            }

            // Spawn blue marbles
            for hex in startingHexes(for: .blue, config: config) {
                let model = MarbleModel(player: .blue, hex: hex)
                gameState.marbles.append(model)

               _ = BoardRenderer.spawnMarble(
                    model: model,
                    config: config,
                    parent: anchor
                )
            }

            // Create and add the board itself
            let boardEntity = BoardRenderer.makeBoardEntity(config: config)
            anchor.addChild(boardEntity)

            arView.scene.addAnchor(anchor)
            boardAnchor = anchor
        }

    }
}
