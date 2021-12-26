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
     * Async allows this to be cancelled part-way through the process.
     */
    func toMDLAsset(device: MTLDevice) async throws -> MDLAsset {

        let allocator = MTKMeshBufferAllocator(device: device)

        let mdlAsset = MDLAsset()

        for anchor in self.meshAnchors {
            try Task.checkCancellation()
            await Task { [anchor] in
                mdlAsset.add(
                    anchor.toMDLMesh(
                        allocator: allocator
                    )
                )
            }.value
        }

        return mdlAsset
    }
}

extension CSMeshSlice {
    /**
     * Generate an `MDLMesh` from the `CSMeshSlice` by simple buffer transforms.
     *
     * Essentially directly from StackOverflow users
     *  [`swiftcoder`](https://stackoverflow.com/a/61104855) and
     *  [`Alexander Gaidukov`](https://stackoverflow.com/a/61327580)
     */
    fileprivate func toMDLMesh(
        allocator: MTKMeshBufferAllocator
    ) -> MDLMesh {
        let vertexData = Data.init(
            bytes: self.vertices.transformVertices(self.transform),
            count: self.vertices.stride * self.vertices.count
        )

        let vertexBuffer = allocator.newBuffer(
            with: vertexData,
            type: .vertex
        )

        let indexCount = self.faces.count * self.faces.indexCountPerPrimitive
        let indexBuffer = allocator.newBuffer(
            with: self.faces.data,
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

extension CSMeshGeometrySource {
    /**
     * Generate a sequence of coordinate-elements from the source's
     * buffer of coordinates based on a `simd_float4x4` transformation matrix.
     */
    fileprivate func transformVertices(
        _ transform: simd_float4x4
    ) -> [Float] {
        var result = [Float]()

        for idx in 0..<self.count {

            let vertexPointer = self.data.advanced(
                by: self.offset + self.stride * idx
            )

            let vertexTransform = vertexPointer.withUnsafeBytes {
                (pointer: UnsafePointer<Float>) -> simd_float4x4 in
                let buffer = UnsafeBufferPointer(
                    start: pointer,
                    count: 3
                )
                var tmpTransform = matrix_identity_float4x4
                tmpTransform.columns.3 = simd_float4(buffer[0], buffer[1], buffer[2], 1)
                return tmpTransform
            }

            let newPosition = (transform * vertexTransform).columns.3
            result.append(newPosition.x)
            result.append(newPosition.y)
            result.append(newPosition.z)
        }

        return result
    }
}
