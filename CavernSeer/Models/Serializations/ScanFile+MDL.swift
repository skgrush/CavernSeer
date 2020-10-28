//
//  ScanFile+MDL.swift
//  CavernSeer
//
//  Created by Samuel Grush on 10/25/20.
//  Copyright © 2020 Samuel K. Grush. All rights reserved.
//

import ARKit /// ARMeshGeometry, ARGeometrySource
import MetalKit /// MTKMeshBufferAllocator

extension ScanFile {
    /**
     * Generate an `MDLAsset` from the `ScanFile`'s mesh data.
     */
    func toMDLAsset(device: MTLDevice) -> MDLAsset {

        let allocator = MTKMeshBufferAllocator(device: device)

        let mdlAsset = MDLAsset()

        self.meshAnchors.forEach {
            anchor in
                mdlAsset.add(
                    anchor.geometry.toMDLMesh(
                        transform: anchor.transform,
                        allocator: allocator
                    )
                )
        }

        return mdlAsset
    }
}

extension ARMeshGeometry {
    /**
     * Generate an `MDLMesh` from the `ARMeshGeometry` by simple buffer transforms.
     *
     * Essentially directly from StackOverflow users
     *  [`swiftcoder`](https://stackoverflow.com/a/61104855) and
     *  [`Alexander Gaidukov`](https://stackoverflow.com/a/61327580)
     */
    fileprivate func toMDLMesh(
        transform: simd_float4x4,
        allocator: MTKMeshBufferAllocator
    ) -> MDLMesh {
        let vertexData = Data.init(
            bytes: self.vertices.transformVertices(transform),
            count: self.vertices.stride * self.vertices.count
        )

        let vertexBuffer = allocator.newBuffer(
            with: vertexData,
            type: .vertex
        )

        let indexCount = self.faces.count * self.faces.indexCountPerPrimitive
        let indexData = Data(
            bytes: self.faces.buffer.contents(),
            count: self.faces.bytesPerIndex * indexCount
        )
        let indexBuffer = allocator.newBuffer(
            with: indexData,
            type: .index
        )

        let submesh = MDLSubmesh(
            indexBuffer: indexBuffer,
            indexCount: indexCount,
            indexType: .uInt32,
            geometryType: .triangles,
            material: nil
        )


        let vertexDescriptor = MDLVertexDescriptor()
        vertexDescriptor.addOrReplaceAttribute(
            MDLVertexAttribute(
                name: MDLVertexAttributePosition,
                format: .float3,
                offset: 0,
                bufferIndex: 0
            )
        )
        vertexDescriptor.layouts[0] = MDLVertexBufferLayout(
            stride: self.vertices.stride
        )

        let mesh = MDLMesh(
            vertexBuffer: vertexBuffer,
            vertexCount: self.vertices.count,
            descriptor: vertexDescriptor,
            submeshes: [submesh]
        )

        return mesh
    }
}


extension ARGeometrySource {
    /**
     * Generate a sequence of coordinate-elements from the `ARGeometrySource`'s
     * buffer of coordinates based on a `simd_float4x4` transformation matrix.
     */
    fileprivate func transformVertices(
        _ transform: simd_float4x4
    ) -> [Float] {
        var result = [Float]()

        for idx in 0..<self.count {
            let vertexPointer = self.buffer.contents().advanced(
                by: self.offset + self.stride * idx
            )
            let vtx = vertexPointer.assumingMemoryBound(
                to: (Float, Float, Float).self
            ).pointee

            var vertexTransform = matrix_identity_float4x4
            vertexTransform.columns.3 = simd_float4(vtx.0, vtx.1, vtx.2, 1)

            let newPosition = (transform * vertexTransform).columns.3
            result.append(newPosition.x)
            result.append(newPosition.y)
            result.append(newPosition.z)
        }

        return result
    }
}
