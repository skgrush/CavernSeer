//
//  ScanFile+Nodes.swift
//  CavernSeer
//
//  Created by Samuel Grush on 7/7/20.
//  Copyright © 2020 Samuel K. Grush. All rights reserved.
//

import ARKit
import SceneKit

extension ScanFile {
    func toSCNNodes() -> [SCNNode] {
        let meshAnchorNodes = self.meshAnchors.map {
            anchor in
            meshGeometryToNode(
                mesh: anchor.geometry,
                transform: anchor.transform
            )
        }

        let stationDict = self.stations.reduce([UUID:SCNNode]()) {
            (dict, station) -> [UUID:SCNNode]
            in
            var dict = dict
            dict[station.identifier] = station.toSCNNode()
            return dict
        }

        let stationNodes = Array(stationDict.values)

        let lineNodes = self.lines.map {
            line in line.toSCNNode(stationDict: stationDict)
        }

        return meshAnchorNodes + lineNodes + stationNodes
    }

    func toSK3DNode() -> SKNode {
        let scnScene = SCNScene()

        let scnNodes = self.toSCNNodes()
        scnNodes.forEach { node in scnScene.rootNode.addChildNode(node) }

        let camera = SCNCamera()
        let cameraNode = SCNNode()
        cameraNode.camera = camera

        if let lookAtTarget = scnScene.rootNode.childNodes.first {
            let constraint = SCNLookAtConstraint(target: lookAtTarget)
            cameraNode.constraints = [ constraint ]
        }

        let node3d = SK3DNode(viewportSize: CGSize(width: 200, height: 200))
        node3d.scnScene = scnScene
        node3d.pointOfView = cameraNode
        node3d.pointOfView!.position = SCNVector3(0, 0, 20)

        return node3d
    }
}

fileprivate func meshGeometryToNode(
    mesh: ARMeshGeometry,
    transform:  simd_float4x4
) -> SCNNode {

    let vertices = SCNGeometrySource(
        buffer: mesh.vertices.buffer,
        vertexFormat: mesh.vertices.format,
        semantic: .vertex,
        vertexCount: mesh.vertices.count,
        dataOffset: mesh.vertices.offset,
        dataStride: mesh.vertices.stride
    )

    let faceData = Data(
        bytesNoCopy: mesh.faces.buffer.contents(),
        count: mesh.faces.buffer.length,
        deallocator: .none
    )

    let faces = SCNGeometryElement(
        data: faceData,
        primitiveType: .triangles,
        primitiveCount: mesh.faces.count,
        bytesPerIndex: mesh.faces.bytesPerIndex
    )


    let node = SCNNode(
        geometry: SCNGeometry(sources: [vertices], elements: [faces])
    )
    node.simdTransform = transform

    let defaultMaterial = SCNMaterial()
    defaultMaterial.isDoubleSided = false
    defaultMaterial.diffuse.contents = UIColor.brown

    node.geometry!.materials = [defaultMaterial]

    return node
}
