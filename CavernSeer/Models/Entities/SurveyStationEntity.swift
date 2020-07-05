//
//  SurveyStationEntity.swift
//  CavernSeer
//
//  Created by Samuel Grush on 7/1/20.
//  Copyright © 2020 Samuel K. Grush. All rights reserved.
//

import Foundation
import RealityKit
import UIKit /// for UIColor

class SurveyStationEntity: Entity, HasAnchoring, HasModel, HasCollision {
    static let defaultRadius: Float = 0.05
    static let defaultColor: UIColor = .gray

    var sphere: ModelEntity!

    init(worldTransform: float4x4) {
        super.init()

        self.collision = CollisionComponent(shapes: [
            ShapeResource.generateSphere(
                radius: SurveyStationEntity.defaultRadius)
        ])

        let mesh = MeshResource.generateSphere(
            radius: SurveyStationEntity.defaultRadius)
        let materials = [SimpleMaterial(
            color: SurveyStationEntity.defaultColor,
            isMetallic: false)]
        self.sphere = ModelEntity(mesh: mesh, materials: materials)

        addChild(self.sphere!)

        self.transform.matrix = worldTransform
    }

    required init() {
        fatalError("init() has not been implemented")
    }

    func highlight(_ doHighlight: Bool) {
        let color: UIColor = doHighlight ? .blue : .gray

        self.sphere.model?.materials[0]
            = SimpleMaterial(color: color, isMetallic: false)
    }

    func lineTo(_ other: SurveyStationEntity) -> SurveyLineEntity {
        return SurveyLineEntity(start: self, end: other)
    }
}
