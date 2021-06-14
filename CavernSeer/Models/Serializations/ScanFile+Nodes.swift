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
        lengthPref: LengthPreference,
        doubleSided: Bool
    ) -> [SCNNode] {
        let meshAnchorNodes = self.meshAnchors.map {
            mesh in
            meshGeometryToNode(
                mesh: mesh,
                color: color,
                quilt: quilt,
                doubleSided: doubleSided
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
    let vertices = sourceCsToScn(source: mesh.vertices)

    let normals = sourceCsToScn(source: mesh.normals)

    let faces = elementCsToScn(element: mesh.faces)

    return SCNGeometry(sources: [vertices, normals], elements: [faces])
}

fileprivate func meshGeometryToNode(
    mesh: CSMeshSlice,
    color: UIColor?,
    quilt: Bool,
    doubleSided: Bool
) -> SCNNode {
    let node = SCNNode(geometry: meshGeometryToSCNGeometry(mesh: mesh))
    node.simdTransform = mesh.transform

    let defaultMaterial = SCNMaterial()
    defaultMaterial.isDoubleSided = doubleSided

    if (quilt) {
        defaultMaterial.diffuse.contents = UIColor(
            hue: CGFloat(drand48()), saturation: 1, brightness: 1, alpha: 1)

    } else if (color != nil) {
        defaultMaterial.diffuse.contents = color
    }

    node.geometry!.materials = [defaultMaterial]

    return node
}

fileprivate func sourceCsToScn(
    source: CSMeshGeometrySource
) -> SCNGeometrySource {
    return SCNGeometrySource(
        data: source.data,
        semantic: source.semantic,
        vectorCount: source.count,
        usesFloatComponents: true,
        componentsPerVector: source.componentsPerVector,
        bytesPerComponent: source.bytesPerComponent,
        dataOffset: source.offset,
        dataStride: source.stride
    )
}

fileprivate func elementCsToScn(
    element: CSMeshGeometryElement
) -> SCNGeometryElement {
    return SCNGeometryElement(
        data: element.data,
        primitiveType: .triangles,
        primitiveCount: element.count,
        bytesPerIndex: element.bytesPerIndex
    )
}
