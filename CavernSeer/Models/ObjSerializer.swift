//
//  ObjSerializer.swift
//  CavernSeer
//
//  Created by Samuel Grush on 10/24/20.
//  Copyright © 2020 Samuel K. Grush. All rights reserved.
//

import Foundation
import ARKit /// MDLAsset, MTLCreateSystemDefaultDevice

class ObjSerializer : ObservableObject {
    let fileExtension: String = "obj"

    /**
     * Generate a mesh from the `ScanFile` and serialize it to the `URL`
     * based on the file extension.
     */
    func serializeScanViaMDL(scan: ScanFile, url: URL) async throws {
        if (
            !MDLAsset.canExportFileExtension(url.pathExtension) ||
            url.pathExtension != fileExtension
        ) {
            throw ObjSerializationError.FileUnsupported
        }
        guard let device = MTLCreateSystemDefaultDevice()
        else { throw ObjSerializationError.DeviceUnsupported }

        let mdlAsset = try await scan.toMDLAsset(device: device)

        try mdlAsset.export(to: url)
    }
}
