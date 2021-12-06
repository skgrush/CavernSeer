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
    private var meshes: [ARMeshAnchor] = []

    mutating func update(_ anchors: [ARMeshAnchor]) {
        anchors.forEach {
            anchor in
            if let idx = self.meshes.firstIndex(of: anchor) {
                self.meshes[idx] = anchor
            } else {
                self.meshes.append(anchor)
            }
        }
    }

    mutating func remove(_ anchors: [ARMeshAnchor]) {
        anchors.forEach {
            anchor in
            if let idx = self.meshes.firstIndex(of: anchor) {
                self.meshes.remove(at: idx)
            }
        }
    }

    mutating func copyAndClear() -> [ARMeshAnchor] {
        let meshes = self.meshes
        self.meshes.removeAll()
        return meshes
    }

    mutating func clear() {
        self.meshes.removeAll()
    }
}
