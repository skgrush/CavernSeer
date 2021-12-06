//
//  CSMeshSliceSnapshot.swift
//  CavernSeer
//
//  Created by Samuel Grush on 6/8/21.
//  Copyright © 2021 Samuel K. Grush. All rights reserved.
//

import Foundation
import ARKit

/**
 * Serializable and portable version of `SnapshotAnchor`.
 */
final class CSMeshSnapshot : NSObject, NSSecureCoding {
    static let supportsSecureCoding = true

    /**
     * jpeg data (or theoretically any `UIImage`-openable data).
     */
    let imageData: Data

    ///Positioning information of where the snapshot was taken from.
    let transform: simd_float4x4
    let identifier: UUID
    let name: String?

    func encode(with coder: NSCoder) {
        coder.encode(self.imageData, forKey: PropertyKeys.imageData)
        coder.encode(self.transform, forPrefix: PropertyKeys.transform)
        coder.encode(self.identifier as NSUUID, forKey: PropertyKeys.identifier)
        coder.encode(self.name, forKey: PropertyKeys.name)
    }

    init?(coder decoder: NSCoder) {
        guard
            let rawData = decoder.decodeObject(
                of: NSData.self,
                forKey: PropertyKeys.imageData
            ) as Data?,
            let ident = decoder.decodeObject(
                of: NSUUID.self,
                forKey: PropertyKeys.identifier
            ) as UUID?
        else { return nil }

        self.imageData = rawData
        self.transform = decoder.decode_simd_float4x4(
            prefix: PropertyKeys.transform
        )
        self.identifier = ident

        if decoder.containsValue(forKey: PropertyKeys.name) {
            self.name = decoder.decodeObject(
                of: NSString.self,
                forKey: PropertyKeys.name
            ) as String?
        } else {
            self.name = nil
        }
    }

    internal init(snapshot: SnapshotAnchor) {
        self.imageData = snapshot.imageData
        self.transform = snapshot.transform
        self.identifier = snapshot.identifier
        self.name = snapshot.name
    }
}


fileprivate struct PropertyKeys {
    static let imageData = "imageData"
    static let transform = "transform"
    static let identifier = "identifier"
    static let name = "name"
}
