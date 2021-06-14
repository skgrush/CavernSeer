//
//  CSMeshSlice.swift
//  CavernSeer
//
//  Created by Samuel Grush on 6/4/21.
//  Copyright © 2021 Samuel K. Grush. All rights reserved.
//

import Foundation
import ARKit

/**
 * Serializable and portable version of `ARMeshAnchor`.
 */
final class CSMeshSlice : NSObject, NSSecureCoding {
    static let supportsSecureCoding = true

    let identifier: UUID
    let transform: simd_float4x4
    let vertices: CSMeshGeometrySource
    let faces: CSMeshGeometryElement
    let normals: CSMeshGeometrySource

    init?(coder decoder: NSCoder) {
        self.identifier = decoder.decodeObject(
            of: NSUUID.self,
            forKey: "identifier"
        )! as UUID
        self.transform = decoder.decode_simd_float4x4(prefix: "transform")
        let vert = decoder.decodeObject(
            of: CSMeshGeometrySource.self,
            forKey: "vertices"
        )
        let fac = decoder.decodeObject(
            of: CSMeshGeometryElement.self,
            forKey: "faces"
        )
        let normals = decoder.decodeObject(
            of: CSMeshGeometrySource.self,
            forKey: "normals"
        )

        if vert == nil || fac == nil || normals == nil {
            return nil
        }

        self.vertices = vert!
        self.faces = fac!
        self.normals = normals!
    }

    init(anchor: ARMeshAnchor) {
        self.identifier = anchor.identifier
        self.transform = anchor.transform
        self.vertices = CSMeshGeometrySource(source: anchor.geometry.vertices, semantic: .vertex)
        self.faces = CSMeshGeometryElement(source: anchor.geometry.faces)
        self.normals = CSMeshGeometrySource(source: anchor.geometry.normals, semantic: .normal)
    }

    func encode(with coder: NSCoder) {
        coder.encode(self.identifier as NSUUID, forKey: "identifier")
        coder.encode(self.transform, forPrefix: "transform")
        coder.encode(self.vertices, forKey: "vertices")
        coder.encode(self.faces, forKey: "faces")
        coder.encode(self.normals, forKey: "normals")
    }
}

/**
 * Serializable and portable version of `ARGeometrySource`.
 * Pulls out the data necessary for rendering to scenes.
 */
final class CSMeshGeometrySource : NSObject, NSSecureCoding {
    static let supportsSecureCoding = true
    private static let supportedMTLVertexFormat: [MTLVertexFormat] = [
        .float, .float2, .float3, .float4,
    ]

    let semantic: Semantic

    let bytesPerComponent: Int
    let componentsPerVector: Int

    let data: Data
    let count: Int
    let format: MTLVertexFormat
    let offset: Int
    let stride: Int

    init?(coder decoder: NSCoder) {
        bytesPerComponent = decoder.decodeInteger(forKey: "bytesPerComponent")
        componentsPerVector = decoder.decodeInteger(forKey: "componentsPerVector")

        count = decoder.decodeInteger(forKey: "count")
        offset = decoder.decodeInteger(forKey: "offset")
        stride = decoder.decodeInteger(forKey: "stride")

        guard
            let fmt = MTLVertexFormat(rawValue: UInt(decoder.decodeInt64(forKey: "format"))),
            let dat = decoder.decodeObject(
                of: NSData.self,
                forKey: "data"
            ) as Data?,
            let rawSem = decoder.decodeObject(
                of: NSString.self,
                forKey: "semantic"
            ) as String?
        else { return nil }
        format = fmt
        data = dat
        semantic = semanticFromRaw(raw: rawSem)
    }

    init(scn: SCNGeometrySource) {
        data = scn.data
        count = scn.data.count
        precondition(scn.usesFloatComponents)
        switch scn.componentsPerVector {
            case 3:
                format = .float3
            case 2:
                format = .float2
            default:
                fatalError("Unexpected componentsPerVector \(scn.componentsPerVector)")
        }
        offset = scn.dataOffset
        stride = scn.dataStride
        componentsPerVector = scn.componentsPerVector
        bytesPerComponent = scn.bytesPerComponent

        semantic = scn.semantic
    }

    init(source: ARGeometrySource, semantic: Semantic) {
        data = Data(
            bytes: source.buffer.contents(),
            count: source.buffer.length
        )
        count = source.count
        format = source.format
        offset = source.offset
        stride = source.stride

        componentsPerVector = source.componentsPerVector
        precondition(Self.supportedMTLVertexFormat.contains(source.format))
        bytesPerComponent = MemoryLayout<Float>.size

        self.semantic = semantic
    }

    func encode(with coder: NSCoder) {
        coder.encode(self.bytesPerComponent, forKey: "bytesPerComponent")
        coder.encode(self.componentsPerVector, forKey: "componentsPerVector")

        coder.encode(self.data, forKey: "data")
        coder.encode(self.count, forKey: "count")
        coder.encode(Int64(self.format.rawValue), forKey: "format")
        coder.encode(self.offset, forKey: "offset")
        coder.encode(self.stride, forKey: "stride")

        coder.encode(self.semantic.rawValue as NSString, forKey: "semantic")
    }

    typealias Semantic = SCNGeometrySource.Semantic
}

/**
 * Serializable and portable version of `ARGeometryElement`.
 * Pulls out the data necessary for rendering to scenes.
 */
final class CSMeshGeometryElement : NSObject, NSSecureCoding {
    typealias PrimitiveType = SCNGeometryPrimitiveType
    static let supportsSecureCoding = true

    let data: Data
    let bytesPerIndex: Int
    let count: Int
    let indexCountPerPrimitive: Int
    let primitiveType: PrimitiveType

    init?(coder decoder: NSCoder) {
        guard
            let dat = decoder.decodeObject(
                of: NSData.self,
                forKey: "data"
            ) as Data?,
            let primitive = PrimitiveType(
                rawValue: decoder.decodeInteger(forKey: "primitiveType")
            )
        else { return nil }
        data = dat
        primitiveType = primitive

        bytesPerIndex = decoder.decodeInteger(forKey: "bytesPerIndex")
        count = decoder.decodeInteger(forKey: "count")
        indexCountPerPrimitive = decoder.decodeInteger(forKey: "indexCountPerPrimitive")
    }

    init(scn: SCNGeometryElement) {
        data = scn.data
        bytesPerIndex = scn.bytesPerIndex
        count = scn.data.count
        let bytesPerPrimitive = count / scn.primitiveCount
        indexCountPerPrimitive = bytesPerPrimitive / bytesPerIndex
        primitiveType = scn.primitiveType
    }

    init(source: ARGeometryElement) {
        data = Data(
            bytes: source.buffer.contents(),
            count: source.buffer.length
        )
        bytesPerIndex = source.bytesPerIndex
        count = source.count
        indexCountPerPrimitive = source.indexCountPerPrimitive
        primitiveType = source.primitiveType.toSCN()
    }

    func encode(with coder: NSCoder) {
        coder.encode(self.data, forKey: "data")
        coder.encode(self.bytesPerIndex, forKey: "bytesPerIndex")
        coder.encode(self.count, forKey: "count")
        coder.encode(self.indexCountPerPrimitive, forKey: "indexCountPerPrimitive")
        coder.encode(self.primitiveType.rawValue, forKey: "primitiveType")
    }
}



fileprivate extension ARGeometryPrimitiveType {
    func toSCN() -> SCNGeometryPrimitiveType {
        switch self {
            case .line:
                return .line
            case .triangle:
                return .triangles
            default:
                fatalError("Unexpected primitiveType \(self)")
        }
    }
}

fileprivate func semanticFromRaw(raw: String) -> CSMeshGeometrySource.Semantic {
    switch raw {
        case CSMeshGeometrySource.Semantic.normal.rawValue:
            return .normal
        case CSMeshGeometrySource.Semantic.vertex.rawValue:
            return .vertex
        case CSMeshGeometrySource.Semantic.texcoord.rawValue:
            return .texcoord
        default:
            fatalError("Unexpected Semantic \(raw)")
    }
}
