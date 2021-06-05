//
//  CSMeshSlice.swift
//  CavernSeer
//
//  Created by Samuel Grush on 6/4/21.
//  Copyright © 2021 Samuel K. Grush. All rights reserved.
//

import Foundation
import ARKit

final class CSMeshSlice : NSObject, NSSecureCoding {
    static let supportsSecureCoding = true

    func encode(with coder: NSCoder) {
        coder.encode(self.identifier as NSUUID, forKey: "identifier")
        coder.encode(self.transform, forPrefix: "transform")
        coder.encode(self.vertices, forKey: "vertices")
        coder.encode(self.faces, forKey: "faces")
    }

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

        if vert == nil || fac == nil {
            return nil
        }

        self.vertices = vert!
        self.faces = fac!
    }

    let identifier: UUID
    let transform: simd_float4x4
    let vertices: CSMeshGeometrySource
    let faces: CSMeshGeometryElement

    init(anchor: ARMeshAnchor) {
        self.identifier = anchor.identifier
        self.transform = anchor.transform
        self.vertices = CSMeshGeometrySource(source: anchor.geometry.vertices)
        self.faces = CSMeshGeometryElement(source: anchor.geometry.faces)
    }
}

final class CSMeshGeometrySource : NSObject, NSSecureCoding {
    static let supportsSecureCoding = true

    func encode(with coder: NSCoder) {
        coder.encode(self.data, forKey: "data")
        coder.encode(self.count, forKey: "count")
        coder.encode(Int64(self.format.rawValue), forKey: "format")
        coder.encode(self.offset, forKey: "offset")
        coder.encode(self.stride, forKey: "stride")
    }

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
            ) as Data?
        else { return nil }
        format = fmt
        data = dat
    }

    let bytesPerComponent: Int
    let componentsPerVector: Int

    let data: Data
    let count: Int
    let format: MTLVertexFormat
    let offset: Int
    let stride: Int

    init(source: ARGeometrySource) {
        data = Data(
            bytes: source.buffer.contents(),
            count: source.buffer.length
        )
        count = source.count
        format = source.format
        offset = source.offset
        stride = source.stride

        componentsPerVector = source.componentsPerVector
//        bytesPerComponent = stride / componentsPerVector
        switch source.format {
            case .float, .float2, .float3, .float4:
                bytesPerComponent = MemoryLayout<Float>.size
            default:
                fatalError("Unsupported MTLVertexFormat \(source.format)")
        }
    }
}

final class CSMeshGeometryElement : NSObject, NSSecureCoding {
    static let supportsSecureCoding = true

    func encode(with coder: NSCoder) {
        coder.encode(self.data, forKey: "data")
        coder.encode(self.bytesPerIndex, forKey: "bytesPerIndex")
        coder.encode(self.count, forKey: "count")
        coder.encode(self.indexCountPerPrimitive, forKey: "indexCountPerPrimitive")
    }

    init?(coder decoder: NSCoder) {
        guard
            let dat = decoder.decodeObject(
                of: NSData.self,
                forKey: "data"
            ) as Data?
        else { return nil }
        data = dat

        bytesPerIndex = decoder.decodeInteger(forKey: "bytesPerIndex")
        count = decoder.decodeInteger(forKey: "count")
        indexCountPerPrimitive = decoder.decodeInteger(forKey: "indexCountPerPrimitive")
    }


    let data: Data
    let bytesPerIndex: Int
    let count: Int
    let indexCountPerPrimitive: Int

    init(source: ARGeometryElement) {
        data = Data(
            bytes: source.buffer.contents(),
            count: source.buffer.length
        )
        bytesPerIndex = source.bytesPerIndex
        count = source.count
        indexCountPerPrimitive = source.indexCountPerPrimitive
    }
}
