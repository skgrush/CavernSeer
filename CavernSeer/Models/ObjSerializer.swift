//
//  ObjSerializer.swift
//  CavernSeer
//
//  Created by Samuel Grush on 10/24/20.
//  Copyright © 2020 Samuel K. Grush. All rights reserved.
//

import Foundation
import ARKit

import SceneKit
import SceneKit.ModelIO
import ModelIO


class ObjSerializer : ObservableObject {
    let fileExtension: String = "obj"

//    func serializeScanViaMDL(scan: ScanFile, url: URL) throws {
//        let mdlAsset = MDLAsset()
//        if !MDLAsset.canExportFileExtension(url.pathExtension) {
//            throw ObjSerializationError.FileUnsupported
//        }
//
//        scan.toMDLMeshes(color: nil).forEach {
//            mesh in
//            mdlAsset.add(mesh)
//        }
//
//        try mdlAsset.export(to: url)
//    }

    /**
     * Convert the scan file to an SCNScene, conver the SCNScene to an MDLAsset, then serialize.
     */
    func serializeScanViaMDLViaSceneKit(
        scan: ScanFile,
        url: URL,
        surfaceColor: UIColor? = nil,
        ambientColor: UIColor = UIColor.red
    ) throws {
        if (
            !MDLAsset.canExportFileExtension(url.pathExtension) ||
            url.pathExtension != fileExtension
        ) {
            throw ObjSerializationError.FileUnsupported
        }

        let scene = SCNScene()

        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(x: 0, y: 10, z: 35)

        scene.rootNode.addChildNode(cameraNode)

        scan.toSCNNodes(color: surfaceColor).forEach {
            node in
                scene.rootNode.addChildNode(node)
        }

        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light!.type = .ambient
        ambientLightNode.light!.color = ambientColor
        scene.rootNode.addChildNode(ambientLightNode)

        let mdlAsset = MDLAsset(scnScene: scene)

        try mdlAsset.export(to: url)
    }

//    func serializeScanViaSceneKitManually(scan: ScanFile, file: FileHandle) {
//        let date = ScanFile.dateFormatter.string(from: scan.getTimestamp())
//        file.write("# Scan taken \(date)\n".data(using: .ascii)!)
//
//        let dummyScene = SCNScene()
//        let nodes = scan.toSCNNodes(color: nil)
//        nodes.forEach { node in dummyScene.rootNode.addChildNode(node) }
//
//        let ambientLightNode = SCNNode()
//        ambientLightNode.light = SCNLight()
//        ambientLightNode.light!.type = .ambient
//        ambientLightNode.light!.color = UIColor.red
//        dummyScene.rootNode.addChildNode(ambientLightNode)
//
//
//        /// SIMD3 === [x,y,z]
// //        var allVertices = [[SIMD3<Float>]]()
//        /// SIMD3 === 3 vertex indices
// //        var allFaces = [[SIMD3<Int>]]()
//
//        var vertexIndexOffset = SIMD3<Int>(1, 1, 1)
//        var nodeIndex = 0
//
//        nodes.forEach {
//            node in
//            guard
//                let geometry = node.geometry,
//                let vertices = geometry.sources.first,
//                let faces = geometry.elements.first
//            else { fatalError("Missing Geometry") }
//
//            let nodeVertices = vertices.data.withUnsafeBytes {
//                $0.load(
//                    fromByteOffset: vertices.dataOffset,
//                    as: [SIMD3<Float>].self
//                )
// //                Array(UnsafeBufferPointer<SIMD3<Float>>(
// //                    start: $0 + vertices.dataOffset,
// //                    count: vertices.vectorCount/vertices.dataStride
// //                ))
//            }.map {
//                node.simdConvertPosition($0, to: dummyScene.rootNode)
//            }
//
//            let nodeFaces = faces.data.withUnsafeBytes {
//                $0.load(fromByteOffset: 0, as: [SIMD3<Int>].self)
//            }.map {
//                /// increment all of the indices by the offset
//                $0 &+ vertexIndexOffset
//            }
//
//            /// update the offset only after generating the faces
//            vertexIndexOffset &+= nodeVertices.count
//
//            /// write the node to a file
//            file.write("# Node \(nodeIndex)\n".data(using: .ascii)!)
//            nodeVertices.forEach {
//                v in
//                file.write("v \(v.x) \(v.y) \(v.z)\n".data(using: .ascii)!)
//            }
//            nodeFaces.forEach {
//                f in
//                file.write("f \(f.x) \(f.y) \(f.z)\n".data(using: .ascii)!)
//            }
//
//            nodeIndex += 1
//        }
//    }

}
