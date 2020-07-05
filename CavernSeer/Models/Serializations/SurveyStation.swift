//
//  SurveyStation.swift
//  CavernSeer
//
//  Created by Samuel Grush on 7/4/20.
//  Copyright © 2020 Samuel K. Grush. All rights reserved.
//

import Foundation
import ARKit

final class SurveyStation: NSObject, NSSecureCoding {
    static var supportsSecureCoding: Bool { true }

    let identifier: UUID
    let transform: float4x4

    init(entity: SurveyStationEntity) {
        guard
            let anchor = entity.anchor,
            let identifier = anchor.anchorIdentifier
        else {
            fatalError("SurveyStationEntity has no anchor")
        }
        self.identifier = identifier
        self.transform = entity.transform.matrix
    }

    required init?(coder decoder: NSCoder) {
        self.identifier = decoder.decodeObject(
            of: NSUUID.self,
            forKey: "identifier")! as UUID
        self.transform = decoder.decode_simd_float4x4(prefix: "transform")
    }

    func encode(with coder: NSCoder) {
        coder.encode(identifier as NSUUID, forKey: "identifer")
        coder.encode(transform, forPrefix: "transform")
    }
}

extension SurveyStation {
    func toSCNNode() -> SCNNode {
        let geo = SCNSphere(radius: 0.1)
        let material = SCNMaterial()
        material.isDoubleSided = false
        material.lightingModel = .constant
        material.diffuse.contents = UIColor.gray
        geo.materials = [material]

        let node = SCNNode(geometry: geo)
        node.simdTransform = self.transform
        return node
    }
}
