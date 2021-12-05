//
//  ARMeshAnchorSet.swift
//  CavernSeer
//
//  Created by Samuel Grush on 12/5/21.
//  Copyright © 2021 Samuel K. Grush. All rights reserved.
//

import Foundation
import ARKit
import RealityKit


struct ARMeshAnchorSet {
    var meshes: [ARMeshAnchor] = []

    mutating func update(_ anchor: ARMeshAnchor) {
        if let idx = meshes.firstIndex(of: anchor) {
            meshes[idx] = anchor
        } else {
            meshes.append(anchor)
        }
    }

    mutating func remove(_ anchor: ARMeshAnchor) {
        if let idx = meshes.firstIndex(of: anchor) {
            meshes.remove(at: idx)
        }
    }

    mutating func copyAndClear() -> [ARMeshAnchor] {
        let meshes = self.meshes
        self.meshes.removeAll()
        return meshes
    }
}
