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

    // MARK: - Coordinator

    final class Coordinator: NSObject {
        weak var arView: ARView?
        var boardAnchor: AnchorEntity?

        // selection state
        var selectedMarble: ModelEntity?
        var originalMaterial: SimpleMaterial?

        // MARK: Tap handling

        @objc func handleTap(_ recognizer: UITapGestureRecognizer) {
            guard let arView else { return }
            let location = recognizer.location(in: arView)

            // 1) No board yet → place the board + initial marble
            if boardAnchor == nil {
                placeBoard(at: location)
                return
            }

            // 2) Tap on a marble → select / deselect
            if let entity = arView.entity(at: location),
               let marbleComp = entity.components[MarbleComponent.self] as? MarbleComponent,
               let marble = entity as? ModelEntity {
                handleMarbleTap(marble, marbleComp: marbleComp)
                return
            }

            // 3) Otherwise, if a marble is selected, treat tap as move target
            handleMoveTap(at: location)
        }

        // MARK: Place board

        private func placeBoard(at screenPoint: CGPoint) {
            guard let arView else { return }

            guard let result = arView
                .raycast(from: screenPoint,
                         allowing: .existingPlaneGeometry,
                         alignment: .horizontal)
                .first
            else { return }

            let config = BoardConfig()
            let anchor = BoardRenderer.makeBoardAnchor(at: result.worldTransform,
                                                       config: config)

            arView.scene.addAnchor(anchor)
            boardAnchor = anchor
        }

        // MARK: Select / deselect marble (highlight green)

        private func handleMarbleTap(_ marble: ModelEntity,
                                     marbleComp: MarbleComponent) {
            // Tapped the already-selected marble → deselect
            if let selected = selectedMarble, selected.id == marble.id {
                if let originalMaterial {
                    selected.model?.materials = [originalMaterial]
                }
                selectedMarble = nil
                originalMaterial = nil
                return
            }

            // Clear previous selection
            if let selected = selectedMarble, let originalMaterial {
                selected.model?.materials = [originalMaterial]
            }

            // Store original material & apply green highlight
            if let mat = marble.model?.materials.first as? SimpleMaterial {
                originalMaterial = mat
                selectedMarble = marble

                var highlighted = mat
                highlighted.baseColor = .color(
                    .init(red: 0.0, green: 1.0, blue: 0.0, alpha: 1.0)
                )
                marble.model?.materials = [highlighted]
            } else {
                // fallback: just track selection
                selectedMarble = marble
                originalMaterial = nil
            }
        }

        // MARK: Move selected marble to adjacent hex

        private func handleMoveTap(at screenPoint: CGPoint) {
            guard let arView,
                  let boardAnchor,
                  let selected = selectedMarble,
                  let marbleComp = selected.components[MarbleComponent.self] as? MarbleComponent
            else { return }

            // Raycast tap to board plane
            guard let result = arView
                .raycast(from: screenPoint,
                         allowing: .existingPlaneGeometry,
                         alignment: .horizontal)
                .first
            else { return }

            let worldPos = SIMD3<Float>(
                result.worldTransform.columns.3.x,
                result.worldTransform.columns.3.y,
                result.worldTransform.columns.3.z
            )

            // Convert to board's local space
            let localPos = boardAnchor.convert(position: worldPos, from: nil)

            let config = BoardConfig()

            // Nearest hex under tap
            let targetHex = BoardRenderer.localPositionToHex(
                x: localPos.x,
                z: localPos.z,
                config: config
            )

            let from = (marbleComp.q, marbleComp.r)

            // Only move if target is on the board AND adjacent
            if BoardRenderer.isValidHex(q: targetHex.q, r: targetHex.r, config: config),
               BoardRenderer.isNeighbor(from: from, to: (targetHex.q, targetHex.r)) {

                let centerXZ = BoardRenderer.hexCenterLocalXZ(
                    q: targetHex.q,
                    r: targetHex.r,
                    config: config
                )
                let radius = BoardRenderer.marbleRadiusMeters(config: config)

                selected.position = SIMD3<Float>(
                    centerXZ.x,
                    radius + 0.001,
                    centerXZ.y   // SIMD2: (x, y) → (x, z)
                )

                // update its logical hex
                selected.components.set(
                    MarbleComponent(q: targetHex.q, r: targetHex.r)
                )
            }

            // Deselect after move attempt
            if let originalMaterial {
                selected.model?.materials = [originalMaterial]
            }
            selectedMarble = nil
            originalMaterial = nil
        }
    }
}
