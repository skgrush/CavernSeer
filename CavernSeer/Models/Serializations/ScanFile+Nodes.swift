//
//  ScanFile+Nodes.swift
//  CavernSeer
//
//  Created by Samuel Grush on 7/7/20.
//  Copyright © 2020 Samuel K. Grush. All rights reserved.
//

import ARKit /// UIColor, SCNNode, ARMeshGeometry, SCNGeometry, Data, simd_float4x4

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
}

fileprivate func meshGeometryToSCNGeometry(
    mesh: ARMeshGeometry
) -> SCNGeometry {
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

    return SCNGeometry(sources: [vertices], elements: [faces])
}

fileprivate func meshGeometryToNode(
    mesh: ARMeshGeometry,
    transform:  simd_float4x4,
    color: UIColor?
) -> SCNNode {
    let node = SCNNode(geometry: meshGeometryToSCNGeometry(mesh: mesh))
    node.simdTransform = transform

    let defaultMaterial = SCNMaterial()
    defaultMaterial.isDoubleSided = false
    if (color != nil) {
        defaultMaterial.diffuse.contents = color
    } else {
        defaultMaterial.diffuse.contents = UIColor(
            hue: CGFloat(drand48()), saturation: 1, brightness: 1, alpha: 1)

    }

    node.geometry!.materials = [defaultMaterial]

    return node
}
