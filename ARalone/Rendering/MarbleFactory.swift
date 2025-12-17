//
//  MarbleFactory.swift
//  ARalone
//
//  Created by lukas on 17.12.25.
//

import RealityKit
import UIKit

enum MarbleFactory {

    static func makeMarble(
        model: MarbleModel,
        config: BoardConfig
    ) -> ModelEntity {

        let radius = BoardRenderer.marbleRadiusMeters(config: config)
        let mesh = MeshResource.generateSphere(radius: radius)

        let color: UIColor = model.player == .red ? .red : .blue
        let material = SimpleMaterial(color: color, isMetallic: false)

        let entity = ModelEntity(mesh: mesh, materials: [material])
        entity.generateCollisionShapes(recursive: false)

        // Store hex position for interaction
        entity.components.set(
            MarbleComponent(q: model.hex.q, r: model.hex.r)
        )

        entity.name = "marble"
        return entity
    }
}
