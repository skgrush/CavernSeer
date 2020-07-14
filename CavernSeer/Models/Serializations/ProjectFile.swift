//
//  ProjectFile.swift
//  CavernSeer
//
//  Created by Samuel Grush on 7/13/20.
//  Copyright © 2020 Samuel K. Grush. All rights reserved.
//

import Foundation
import ARKit

final class ProjectFile : NSSecureCoding {
    static let supportsSecureCoding: Bool = true
    static let currentEncodingVersion: Int32 = 1

    let encodingVersion: Int32

    let timestamp: Date
    let name: String

    let scans: [ProjectScanRelation]

    init(name: String, scans: [ProjectScanRelation]) {
        self.encodingVersion = ProjectFile.currentEncodingVersion
        self.timestamp = Date()
        self.name = name
        self.scans = scans
    }

    required init?(coder decoder: NSCoder) {
        self.encodingVersion = decoder.decodeInt32(forKey: PropertyKeys.version)
        self.timestamp = decoder.decodeObject(
            of: NSDate.self,
            forKey: PropertyKeys.timestamp
        )! as Date
        self.name = decoder.decodeObject(
            of: NSString.self,
            forKey: PropertyKeys.name
        )! as String
        self.scans = decoder.decodeObject(
            of: [NSArray.self, ProjectScanRelation.self],
            forKey: PropertyKeys.scans
        ) as! [ProjectScanRelation]
    }

    func encode(with coder: NSCoder) {
        coder.encode(encodingVersion, forKey: PropertyKeys.version)
        coder.encode(timestamp, forKey: PropertyKeys.timestamp)
        coder.encode(name, forKey: PropertyKeys.name)
        coder.encode(scans as NSArray, forKey: PropertyKeys.scans)
    }

    private struct PropertyKeys {
        static let version = "version"
        static let timestamp = "timestamp"
        static let name = "name"
        static let scans = "scans"
    }
}



final class ProjectScanRelation : NSSecureCoding {
    typealias PositionType = Int32
    static let supportsSecureCoding: Bool = true

    let scan: ScanFile
    /// transformation of this `ScanFile` from the common origin
    let transform: simd_float4x4
    /// which scan (in the `ProjectFile.scans` array) is this one positioned relative to
    let positionedRelativeToScan: PositionType

    init(scan: ScanFile, transform: simd_float4x4, relative: PositionType) {
        self.scan = scan
        self.transform = transform
        self.positionedRelativeToScan = relative
    }

    required init?(coder decoder: NSCoder) {
        self.scan = decoder.decodeObject(
            of: ScanFile.self,
            forKey: PropertyKeys.scan
        )!
        self.transform = decoder.decode_simd_float4x4(
            prefix: PropertyKeys.transform
        )
        self.positionedRelativeToScan =
            decoder.decodeInt32(forKey: PropertyKeys.positionedRelativeToScan)
    }

    func encode(with coder: NSCoder) {
        coder.encode(scan, forKey: PropertyKeys.scan)
        coder.encode(transform, forPrefix: PropertyKeys.transform)
        coder.encode(
            positionedRelativeToScan,
            forKey: PropertyKeys.positionedRelativeToScan
        )
    }


    private struct PropertyKeys {
        static let scan = "scan"
        static let transform = "transform"
        static let positionedRelativeToScan = "relative"
    }
}
