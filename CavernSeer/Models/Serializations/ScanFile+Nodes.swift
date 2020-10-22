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
    func toSCNNodes(color: UIColor?) -> [SCNNode] {
        let meshAnchorNodes = self.meshAnchors.map {
            anchor in
            meshGeometryToNode(
                mesh: anchor.geometry,
                transform: anchor.transform,
                color: color
            )
        }

        let stationDict = self.stations.reduce(
            [SurveyStation.Identifier: SCNNode]()
        ) {
            (dict, station)
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

//    func toSK3DNode(color: UIColor? = .clear) -> SKNode {
//        let scnScene = SCNScene()
//
//        let scnNodes = self.toSCNNodes(color: color)
//        scnNodes.forEach { node in scnScene.rootNode.addChildNode(node) }
//
//        let camera = SCNCamera()
//        camera.usesOrthographicProjection = true
//        camera.orthographicScale = 50
////        camera.zNear = 0
//        camera.zFar = 8
//
//        let cameraNode = SCNNode()
//        cameraNode.camera = camera
//        /// position above
//        cameraNode.position = SCNVector3(x: 0, y: 0, z: 5000)
//        /// look down
//        // cameraNode.eulerAngles = SCNVector3Make(.pi / -2, 0, 0)
//
//        let node3d = SK3DNode(viewportSize: CGSize(width: 2000, height: 2000))
//        node3d.scnScene = scnScene
//        node3d.pointOfView = cameraNode
//
//        return node3d
//    }
}

fileprivate func meshGeometryToNode(
    mesh: ARMeshGeometry,
    transform:  simd_float4x4,
    color: UIColor?
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
    if (color != nil) {
        defaultMaterial.diffuse.contents = color
    }

    node.geometry!.materials = [defaultMaterial]

    return node
}
