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

    func serializeScanViaMDL(scan: ScanFile, url: URL) throws {
        if (
            !MDLAsset.canExportFileExtension(url.pathExtension) ||
            url.pathExtension != fileExtension
        ) {
            throw ObjSerializationError.FileUnsupported
        }
        guard let device = MTLCreateSystemDefaultDevice()
        else { throw ObjSerializationError.DeviceUnsupported }

        let mdlAsset = scan.toMDLAsset(device: device)

        try mdlAsset.export(to: url)
    }
}
