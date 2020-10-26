//
//  SurveyLine.swift
//  CavernSeer
//
//  Created by Samuel Grush on 7/4/20.
//  Copyright © 2020 Samuel K. Grush. All rights reserved.
//

import Foundation
import ARKit /// SCN*, simd_float3, UIColor

final class SurveyLine: NSObject, NSSecureCoding {
    static var supportsSecureCoding: Bool {
        true
    }

    let startIdentifier: SurveyStation.Identifier
    let endIdentifier: SurveyStation.Identifier

    var identifier: String {
        get { "\(startIdentifier.uuidString)_\(endIdentifier.uuidString)" }
    }

    init(entity: SurveyLineEntity) {
        guard
            let startId = entity.start.anchor?.anchorIdentifier,
            let endId = entity.end.anchor?.anchorIdentifier
        else {
            fatalError("SurveyLine's start/end has no anchor")
        }

        self.startIdentifier = startId
        self.endIdentifier = endId
    }

    required init?(coder decoder: NSCoder) {
        self.startIdentifier = decoder.decodeObject(
            of: NSUUID.self,
            forKey: PropertyKeys.startId)! as SurveyStation.Identifier
        self.endIdentifier = decoder.decodeObject(
            of: NSUUID.self,
            forKey: PropertyKeys.endId)! as SurveyStation.Identifier
    }

    func encode(with coder: NSCoder) {
        coder.encode(startIdentifier as NSUUID, forKey: PropertyKeys.startId)
        coder.encode(endIdentifier as NSUUID, forKey: PropertyKeys.endId)
    }
}


extension SurveyLine {
    func toSCNNode(stationDict: [SurveyStation.Identifier:SCNNode]) -> SCNNode {
        guard
            let start = stationDict[self.startIdentifier],
            let end = stationDict[self.endIdentifier]
        else {
            fatalError("SurveyLine.toSCNNode start/end not in dict")
        }

        let startPos = start.simdPosition
        let endPos = end.simdPosition

        let lineNode = drawLine(startPos, endPos)

        let textWrapperNode = drawText(startPos, endPos)
        lineNode.addChildNode(textWrapperNode)

        return lineNode
    }

    private func drawLine(
        _ startPos: simd_float3,
        _ endPos: simd_float3
    ) -> SCNNode {
        let vertices = [startPos, endPos]

        let data = NSData(
            bytes: vertices,
            length: MemoryLayout<simd_float3>.size * 2
        ) as Data

        let vertexSource = SCNGeometrySource(
            data: data,
            semantic: .vertex,
            vectorCount: 2,
            usesFloatComponents: true,
            componentsPerVector: 3,
            bytesPerComponent: MemoryLayout<Float>.size,
            dataOffset: 0,
            dataStride: MemoryLayout<simd_float3>.stride
        )

        let indices: [Int32] = [0, 1]
        let indexData = NSData(
            bytes: indices,
            length: MemoryLayout<Int32>.size * 2
        ) as Data

        let element = SCNGeometryElement(
            data: indexData,
            primitiveType: .line,
            primitiveCount: 1,
            bytesPerIndex: MemoryLayout<Int32>.size
        )

        let geo = SCNGeometry(sources: [vertexSource], elements: [element])

        let material = SCNMaterial()
        material.lightingModel = .constant
        material.diffuse.contents = UIColor.green
        geo.materials = [material]

        return SCNNode(geometry: geo)
    }

    private func drawText(
        _ startPos: simd_float3,
        _ endPos: simd_float3
    ) -> SCNNode {
        let constraints = SCNBillboardConstraint()
        constraints.freeAxes = .Y
        let distance = simd_length(startPos - endPos)
        let textGeo = SCNText(string: "\(distance)m", extrusionDepth: 0.01)
        textGeo.flatness = 0
        textGeo.alignmentMode = CATextLayerAlignmentMode.center.rawValue

        let textMat = SCNMaterial()
        textMat.diffuse.contents = UIColor.blue
        textMat.isDoubleSided = true
        textGeo.materials = [textMat]
        textGeo.font = UIFont(name: "System", size: 32)

        let max = textGeo.boundingBox.max
        let min = textGeo.boundingBox.min

        let tx = (max.x - min.x) / 2.0
        let ty = min.y
        let tz = Float(1 / 2.0)

        let textNode = SCNNode(geometry: textGeo)
        textNode.scale = SCNVector3(0.005, 0.005, 0.005)
        textNode.pivot = SCNMatrix4MakeTranslation(tx, ty, tz)

        let textWrapperNode = SCNNode()
        textWrapperNode.addChildNode(textNode)
        textWrapperNode.constraints = [constraints]
        textWrapperNode.position = SCNVector3(
            x: ((startPos.x + endPos.x) / 2.0),
            y: (startPos.y + endPos.y) / 2.0 + 0.01,
            z: (startPos.z + endPos.z) / 2.0
        )

        return textWrapperNode
    }
}


fileprivate struct PropertyKeys {
    static let startId = "startIdentifier"
    static let endId = "endIdentifier"
}
