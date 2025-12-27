//
//  HandleTap.swift
//  ARalone
//
//  Created by lukas on 27.12.25.
//

import Foundation
import RealityKit
import ARKit

extension ARViewContainer.Coordinator {

    // MARK: - Main tap entry

    @objc func handleTap(_ recognizer: UITapGestureRecognizer) {
        guard let arView else { return }
        let location = recognizer.location(in: arView)

        // 1) No board yet → place the board
        if boardAnchor == nil {
            placeBoard(at: location)
            return
        }

        // 2) Tap on a marble
        if let entity = arView.entity(at: location),
           let marble = entity as? ModelEntity,
           let marbleComp = marble.components[MarbleComponent.self] as? MarbleComponent {

            // If no marble selected yet → attempt selection
            if selectedMarble == nil {
                handleMarbleTap(marble, marbleComp: marbleComp)
                return
            }

            // If a marble is already selected → treat as move attempt
            handleMoveTap(at: location)
            return
        }

        // 3) Otherwise → attempt move
        handleMoveTap(at: location)
    }

    // MARK: - Select / deselect marble

    func handleMarbleTap(
        _ marble: ModelEntity,
        marbleComp: MarbleComponent
    ) {
        // Only allow selecting current player's marble
        guard marbleComp.player == gameState.currentPlayer else {
            return
        }
        // Tapped the already-selected marble → deselect
        if let selected = selectedMarble, selected.id == marble.id {
            restoreSelection()
            return
        }

        // Clear previous selection
        restoreSelection()

        // Store original material & apply green highlight
        if let mat = marble.model?.materials.first as? SimpleMaterial {
            originalMaterial = mat
            selectedMarble = marble

            var highlighted = mat
            highlighted.baseColor = .color(
                .init(red: 0, green: 1, blue: 0, alpha: 1)
            )
            marble.model?.materials = [highlighted]
        } else {
            selectedMarble = marble
        }
    }

    // MARK: - Attempt marble move

    func handleMoveTap(at screenPoint: CGPoint) {
        guard let arView,
              let boardAnchor,
              selectedMarble != nil
        else { return }

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

        let localPos = boardAnchor.convert(position: worldPos, from: nil)
        let config = BoardConfig()

        let target = BoardRenderer.localPositionToHex(
            x: localPos.x,
            z: localPos.z,
            config: config
        )

        let targetHex = HexCoordinate(target)
        
        tryMoveSelectedMarble(to: targetHex, config: config)

        restoreSelection()
    }

    // MARK: - Move logic bridge

    private func tryMoveSelectedMarble(
        to targetHex: HexCoordinate,
        config: BoardConfig
    ) {
        guard let selected = selectedMarble,
              let marbleComp = selected.components[MarbleComponent.self] as? MarbleComponent
        else { return }

        let fromHex = HexCoordinate(
            q: marbleComp.q,
            r: marbleComp.r
        )

        guard let idx = gameState.marbles.firstIndex(
            where: { $0.hex == fromHex }
        ) else { return }
        
        let marbleCountBefore = gameState.marbles.count
        
        let moved = gameState.moveMarble(
            at: idx,
            to: targetHex,
            config: config
        )

        guard moved else { return }
        
        let marbleCountAfter = gameState.marbles.count
        let pushHappened = marbleCountAfter < marbleCountBefore

        if pushHappened {
            removeDefenderEntity(at: targetHex)
        }

        let centerXZ = BoardRenderer.hexCenterLocalXZ(
            q: targetHex.q,
            r: targetHex.r,
            config: config
        )

        let radius = BoardRenderer.marbleRadiusMeters(config: config)

        selected.position = SIMD3<Float>(
            centerXZ.x,
            radius + 0.001,
            centerXZ.y
        )

        selected.components.set(
            MarbleComponent(
                q: targetHex.q,
                r: targetHex.r,
                playerRaw: marbleComp.playerRaw
            )
        )

        updateBoardTexture(config: config)
    }
    private func removeDefenderEntity(at hex: HexCoordinate) {
        guard let boardAnchor else { return }

        for child in boardAnchor.children {
            guard let marble = child as? ModelEntity,
                  let comp = marble.components[MarbleComponent.self] as? MarbleComponent
            else { continue }

            if comp.q == hex.q && comp.r == hex.r {
                marble.removeFromParent()
                return
            }
        }
    }

    @MainActor
    func updateBoardTexture(config: BoardConfig) {
        print("updateBoardTexture called, boardEntity =", boardEntity as Any)
        guard let boardEntity else { return }

        let img = BoardTextureHex.makeHexBoardImage(
            config: config,
            claimedHexes: gameState.claimedHexes
        )

        guard let cg = img.cgImage,
              let tex = try? TextureResource(
                image: cg,
                options: .init(semantic: .color)
              )
        else { return }

        var material = UnlitMaterial()
        material.baseColor = .texture(tex)

        boardEntity.model?.materials = [material]
    }

    private func restoreSelection() {
        if let selected = selectedMarble,
           let originalMaterial {
            selected.model?.materials = [originalMaterial]
        }
        selectedMarble = nil
        originalMaterial = nil
    }
}
