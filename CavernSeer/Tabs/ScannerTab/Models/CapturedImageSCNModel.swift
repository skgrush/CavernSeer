//
//  CapturedImageSCNModel.swift
//  CavernSeer
//
//  Created by Samuel Grush on 6/12/21.
//  Copyright © 2021 Samuel K. Grush. All rights reserved.
//

import Foundation
import ARKit

final class CSCapture : NSObject, NSSecureCoding {
    static let supportsSecureCoding = true

    let identifier: UUID
    let sources: [CSMeshGeometrySource]
    let elements: [CSMeshGeometryElement]
    let jpegData: Data

    convenience init(cap: CapturedImageSCNModel) {
        self.init(
            identifier: cap.identifier,
            sources: cap.geometry.sources.map { CSMeshGeometrySource(scn: $0) },
            elements: cap.geometry.elements.map { CSMeshGeometryElement(scn: $0) },
            jpegData: cap.jpegData
        )
    }

    required init?(coder decoder: NSCoder) {
        guard
            let identifier = decoder.decodeObject(
                of: NSUUID.self, forKey: "identifier"
            ) as UUID?,
            let sources = decoder.decodeObject(
                of: [NSArray.self, CSMeshGeometrySource.self],
                forKey: "sources"
            ) as? [CSMeshGeometrySource],
            let elements = decoder.decodeObject(
                of: [NSArray.self, CSMeshGeometryElement.self],
                forKey: "elements"
            ) as? [CSMeshGeometryElement],
            let jpegData = decoder.decodeObject(
                of: NSData.self,
                forKey: "jpegData"
            ) as Data?
        else { return nil }

        self.identifier = identifier
        self.sources = sources
        self.elements = elements
        self.jpegData = jpegData
    }

    init(
        identifier: UUID,
        sources: [CSMeshGeometrySource],
        elements: [CSMeshGeometryElement],
        jpegData: Data
    ) {
        self.identifier = identifier
        self.sources = sources
        self.elements = elements
        self.jpegData = jpegData
    }

    func encode(with coder: NSCoder) {
        coder.encode(identifier as NSUUID, forKey: "identifier")
        coder.encode(sources as NSArray, forKey: "sources")
        coder.encode(elements as NSArray, forKey: "elements")
        coder.encode(jpegData, forKey: "jpegData")
    }
}

/**
 *
 * Based on code from
 * [Pavan K](https://stackoverflow.com/a/61790146)
 * Creates SCNGeometry and relevant data for storing describing captured image mesh.
 */
class CapturedImageSCNModel {

    let identifier: UUID
    let geometry: SCNGeometry
    let jpegData: Data

    init(anchor: ARMeshAnchor, camera: ARCamera, jpegData: Data) {
        self.jpegData = jpegData
        let textureSource =
            Self.texCoordsToSource(
                Self.getWorldVertices(
                    vertices: anchor.geometry.vertices,
                    transform: anchor.transform
                )
                .map { Self.arVertexToCameraPoint(pt: $0, camera: camera) }
            )
        assert(textureSource.semantic == .texcoord)

        let verts = anchor.geometry.vertices
        let norms = anchor.geometry.normals
        let faces = anchor.geometry.faces
        let verticesSource = SCNGeometrySource(
            buffer: verts.buffer,
            vertexFormat: verts.format,
            semantic: .vertex,
            vertexCount: verts.count,
            dataOffset: verts.offset,
            dataStride: verts.stride
        )
        let normalsSource = SCNGeometrySource(
            buffer: norms.buffer,
            vertexFormat: norms.format,
            semantic: .normal,
            vertexCount: norms.count,
            dataOffset: norms.offset,
            dataStride: norms.stride
        )
        assert(faces.primitiveType == .triangle)

        let buff = faces.buffer.contents()
        let data = Data(bytes: buff, count: faces.buffer.length)
        let facesElement = SCNGeometryElement(
            data: data,
            primitiveType: .triangles,
            primitiveCount: faces.count,
            bytesPerIndex: faces.bytesPerIndex
        )

        assert(textureSource.vectorCount == norms.count)

        let sources = [
            verticesSource,
            normalsSource,
            textureSource
        ]

        geometry = SCNGeometry(sources: sources, elements: [facesElement])
        identifier = anchor.identifier
    }

    static func getImage(frame: ARFrame) -> UIImage? {
        let pixelBuffer = frame.capturedImage
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        guard
            let cameraImage = CIContext().createCGImage(ciImage, from: ciImage.extent)
        else {
            debugPrint("Couldn't construct cameraImage")
            return nil
        }
        return UIImage(cgImage: cameraImage)
    }

    private static func getWorldVertices(
        vertices: ARGeometrySource,
        transform: simd_float4x4
    ) -> [simd_float3] {
        precondition(vertices.format == .float3)

//        let bufContents = vertices.buffer.contents()
//        var offsetBy = vertices.offset
        return (0..<vertices.count).map { //Int -> simd_float3 in
            idx in
//            offsetBy += vertices.stride
//            let vtxPointer = bufContents.advanced(by: offsetBy)
            let vtxPointer = vertices.buffer.contents().advanced(by: vertices.offset + idx * vertices.stride)
            let vtx = vtxPointer.assumingMemoryBound(to: simd_float3.self).pointee
            let anchoredPosition4 = simd_float4(vtx.x, vtx.y, vtx.z, 1)

            let worldPos4 = simd_mul(transform, anchoredPosition4)
            return simd_float3(worldPos4.x, worldPos4.y, worldPos4.z)
        }
    }

    private static func arVertexToCameraPoint(
        pt: simd_float3,
        camera: ARCamera
    ) -> simd_float2 {
        let size = camera.imageResolution
        let projected = camera.projectPoint(
            pt,
            orientation: .portrait,
            viewportSize: CGSize(
                width: size.height,
                height: size.width
            )
        )
        // TODO: check if x and y are flipped
        return simd_float2(
            Float(projected.y / size.width),
            Float(1.0 - projected.x / size.height)

        )
    }

    private static func texCoordsToSource(
        _ coords: [simd_float2]
    ) -> SCNGeometrySource {
        let stride = MemoryLayout<simd_float2>.stride
        let bytePerComponent = MemoryLayout<Float>.stride
        let data = Data(bytes: coords, count: stride * coords.count)
        return SCNGeometrySource(
            data: data,
            semantic: .texcoord,
            vectorCount: coords.count,
            usesFloatComponents: true,
            componentsPerVector: 2,
            bytesPerComponent: bytePerComponent,
            dataOffset: 0,
            dataStride: stride
        )
    }
}
