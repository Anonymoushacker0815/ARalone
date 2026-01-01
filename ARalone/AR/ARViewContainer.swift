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
    @Binding var uiState: GameUIState
    let gameState: GameState
    
    func makeCoordinator() -> Coordinator {
        Coordinator(gameState: gameState)
    }


    func makeUIView(context: Context) -> ARView {
        Coordinator.shared = context.coordinator
        let arView = ARView(frame: .zero)
        arView.isUserInteractionEnabled = uiState != .menu

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
        context.coordinator.uiState = $uiState
        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {
        uiView.isUserInteractionEnabled = uiState != .menu
    }

    final class Coordinator: NSObject {
        weak var arView: ARView?
        var boardAnchor: AnchorEntity?
        let gameState: GameState
        init(gameState: GameState) {
                self.gameState = gameState
            }
        var uiState: Binding<GameUIState>?
        static weak var shared: Coordinator?

        // selection state
        var selectedMarble: ModelEntity?
        var originalMaterial: SimpleMaterial?
        
        var boardEntity: ModelEntity?

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
            // If this is the first board placement → initialize game
            if gameState.marbles.isEmpty {
                setupNewGame(config: config)
            }
            // Create board
            let board = BoardRenderer.makeBoardEntity(config: config)
            anchor.addChild(board)
            self.boardEntity = board
            
            // Render marbles & hex colors from state
            renderBoardFromGameState(
                anchor: anchor,
                config: config
            )

            arView.scene.addAnchor(anchor)
            boardAnchor = anchor

            updateBoardTexture(config: config)
            uiState?.wrappedValue = .playing
        }
        func renderBoardFromGameState(
            anchor: AnchorEntity,
            config: BoardConfig
        ) {
            // Spawn marbles
            for model in gameState.marbles {
                _ = BoardRenderer.spawnMarble(
                    model: model,
                    config: config,
                    parent: anchor
                )
            }

            // Reapply claimed hex colors
            updateBoardTexture(config: config)
        }
        func resetGame() {
            gameState.marbles.removeAll()
            gameState.claimedHexes.removeAll()
            gameState.currentPlayer = .red
            gameState.lastPushDelta = nil
            gameState.redCaptured = 0
            gameState.blueCaptured = 0
        }
        func setupNewGame(config: BoardConfig) {
            gameState.marbles.removeAll()
            gameState.claimedHexes.removeAll()
            gameState.currentPlayer = .red
            gameState.lastPushDelta = nil

            // Spawn red marbles
            for hex in startingHexes(for: .red, config: config) {
                let model = MarbleModel(player: .red, hex: hex)
                gameState.marbles.append(model)
                gameState.claimedHexes[hex] = .red
            }

            // Spawn blue marbles
            for hex in startingHexes(for: .blue, config: config) {
                let model = MarbleModel(player: .blue, hex: hex)
                gameState.marbles.append(model)
                gameState.claimedHexes[hex] = .blue
            }
        }
        func undo() {
            guard
                let arView,
                let oldAnchor = boardAnchor
            else { return }

            // 1️⃣ Undo logical game state
            gameState.undoLastMove()

            // 2️⃣ Save current board transform
            let worldTransform = oldAnchor.transformMatrix(relativeTo: nil)

            // 3️⃣ Remove old board
            arView.scene.removeAnchor(oldAnchor)
            boardAnchor = nil
            boardEntity = nil
            selectedMarble = nil
            originalMaterial = nil

            // 4️⃣ Create new anchor at same position
            let newAnchor = AnchorEntity(world: worldTransform)

            let config = BoardConfig()

            // 5️⃣ Create board
            let board = BoardRenderer.makeBoardEntity(config: config)
            newAnchor.addChild(board)
            boardEntity = board

            // 6️⃣ Render marbles + hex colors from state
            renderBoardFromGameState(
                anchor: newAnchor,
                config: config
            )

            // 7️⃣ Add back to scene
            arView.scene.addAnchor(newAnchor)
            boardAnchor = newAnchor
        }
        func replaceBoard() {
            guard let arView else { return }

            // Remove old board anchor
            if let anchor = boardAnchor {
                arView.scene.removeAnchor(anchor)
            }

            boardAnchor = nil
            boardEntity = nil
            selectedMarble = nil
            originalMaterial = nil

            // Go back to placement mode
            uiState?.wrappedValue = .placingBoard
        }
        func restartGame() {
            guard let arView else { return }

            if let anchor = boardAnchor {
                arView.scene.removeAnchor(anchor)
            }

            boardAnchor = nil
            boardEntity = nil
            selectedMarble = nil
            originalMaterial = nil

            gameState.marbles.removeAll()
            gameState.claimedHexes.removeAll()
            gameState.currentPlayer = .red
            gameState.lastPushDelta = nil
            gameState.redCaptured = 0
            gameState.blueCaptured = 0
            
            uiState?.wrappedValue = .placingBoard
        }
        func rollMarble(
            _ marble: ModelEntity,
            from start: SIMD3<Float>,
            to end: SIMD3<Float>,
            duration: TimeInterval = 0.25
        ) {
            let distance = simd_length(end - start)
            guard distance > 0 else { return }

            // Approximate rotation angle: distance / radius
            let radius = simd_length(marble.visualBounds(relativeTo: marble).extents) * 0.5
            let angle = distance / max(radius, 0.0001)

            let direction = simd_normalize(end - start)
            let rotationAxis = simd_normalize(SIMD3<Float>(-direction.z, 0, direction.x))

            let rotation = simd_quatf(angle: angle, axis: rotationAxis)

            var transform = marble.transform
            transform.translation = end
            transform.rotation = rotation * transform.rotation

            marble.move(
                to: transform,
                relativeTo: marble.parent,
                duration: duration,
                timingFunction: .easeInOut
            )
        }
    }
}

