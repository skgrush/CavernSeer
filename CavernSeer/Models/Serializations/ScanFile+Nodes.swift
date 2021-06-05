//
//  ScanFile+Nodes.swift
//  CavernSeer
//
//  Created by Samuel Grush on 7/7/20.
//  Copyright © 2020 Samuel K. Grush. All rights reserved.
//

import ARKit /// UIColor, SCNNode, ARMeshGeometry, SCNGeometry, Data, simd_float4x4

extension ScanFile {
    func toSCNNodes(
        color: UIColor?,
        quilt: Bool,
        lengthPref: LengthPreference
    ) -> [SCNNode] {
        let meshAnchorNodes = self.meshAnchors.map {
            mesh in
            meshGeometryToNode(
                mesh: mesh,
                color: color,
                quilt: quilt
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
            line in
            line.toSCNNode(stationDict: stationDict, lengthPref: lengthPref)
        }

        return meshAnchorNodes + lineNodes + stationNodes
    }
}

fileprivate func meshGeometryToSCNGeometry(
    mesh: CSMeshSlice
) -> SCNGeometry {
    let vertices = SCNGeometrySource(
        data: mesh.vertices.data,
        semantic: .vertex,
        vectorCount: mesh.vertices.count,
        usesFloatComponents: true,
        componentsPerVector: mesh.vertices.componentsPerVector,
        bytesPerComponent: mesh.vertices.bytesPerComponent,
        dataOffset: mesh.vertices.offset,
        dataStride: mesh.vertices.stride
    )

    let faces = SCNGeometryElement(
        data: mesh.faces.data,
        primitiveType: .triangles,
        primitiveCount: mesh.faces.count,
        bytesPerIndex: mesh.faces.bytesPerIndex
    )

    return SCNGeometry(sources: [vertices], elements: [faces])
}

fileprivate func meshGeometryToNode(
    mesh: CSMeshSlice,
    color: UIColor?,
    quilt: Bool
) -> SCNNode {
    let node = SCNNode(geometry: meshGeometryToSCNGeometry(mesh: mesh))
    node.simdTransform = mesh.transform

    let defaultMaterial = SCNMaterial()
    defaultMaterial.isDoubleSided = false

    if (quilt) {
        defaultMaterial.diffuse.contents = UIColor(
            hue: CGFloat(drand48()), saturation: 1, brightness: 1, alpha: 1)

    } else if (color != nil) {
        defaultMaterial.diffuse.contents = color
    }

    node.geometry!.materials = [defaultMaterial]

    return node
}
