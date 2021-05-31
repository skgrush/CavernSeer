//
//  ProjectFile.swift
//  CavernSeer
//
//  Created by Samuel Grush on 7/13/20.
//  Copyright © 2020 Samuel K. Grush. All rights reserved.
//

import Foundation
import ARKit /// simd_float4x4

final class ProjectFile : NSObject, StoredFileProtocol {
    typealias CacheType = ProjectCacheFile
    static let filePrefix = "proj"
    static let fileExtension: String = "cavernseerproj"

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
        let version = decoder.decodeInt32(forKey: PropertyKeys.version)
        self.encodingVersion = version

        if (version == 1) {
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
        } else {
            fatalError("Unexpected encoding version \(version)")
        }
    }

    func encode(with coder: NSCoder) {
        coder.encode(ProjectFile.currentEncodingVersion,
                     forKey: PropertyKeys.version)
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

    func createCacheFile(thisFileURL: URL) -> ProjectCacheFile {
        return ProjectCacheFile(
            realFileURL: thisFileURL,
            timestamp: timestamp,
            displayName: name,
            img: nil
        )
    }
}


extension ProjectFile {
    /// affected by the encoding version of its parent
    @objc(ProjectFile_ProjectScanRelation)
    final class ProjectScanRelation : NSObject, NSSecureCoding {
        typealias PositionType = Int32
        static let supportsSecureCoding: Bool = true

        let encodingVersion: Int32

        let scan: ScanFile
        /// transformation of this `ScanFile` from the common origin
        let transform: simd_float4x4
        /// which scan (in the `ProjectFile.scans` array) is this one positioned relative to
        let positionedRelativeToScan: PositionType



        init(scan: ScanFile, transform: simd_float4x4, relative: PositionType) {
            self.encodingVersion = ProjectFile.currentEncodingVersion
            self.scan = scan
            self.transform = transform
            self.positionedRelativeToScan = relative
        }

        required init?(coder decoder: NSCoder) {
            let version = decoder.decodeInt32(forKey: PropertyKeys.version)
            self.encodingVersion = version

            if version == 1 {
                self.scan = decoder.decodeObject(
                    of: ScanFile.self,
                    forKey: PropertyKeys.scan
                )!
                self.transform = decoder.decode_simd_float4x4(
                    prefix: PropertyKeys.transform
                )
                self.positionedRelativeToScan =
                    decoder.decodeInt32(forKey: PropertyKeys.positionedRelativeToScan)
            } else {
                fatalError("Unexpected encoding version \(version)")
            }
        }

        func encode(with coder: NSCoder) {
            coder.encode(ProjectFile.currentEncodingVersion,
                         forKey: PropertyKeys.version)
            coder.encode(scan, forKey: PropertyKeys.scan)
            coder.encode(transform, forPrefix: PropertyKeys.transform)
            coder.encode(
                positionedRelativeToScan,
                forKey: PropertyKeys.positionedRelativeToScan
            )
        }


        private struct PropertyKeys {
            static let version = "version"
            static let scan = "scan"
            static let transform = "transform"
            static let positionedRelativeToScan = "relative"
        }
    }

// TODO
//    /// how station pairs/groups positionings are resolved
//    enum StationPositioningType : Int32 {
//        /// the origin
//        case OriginFixed = 1
//    }
//
//    /// joins two scans via common stations
//    @objc(ProjectFile_StationPair)
//    final class StationPair : NSObject, Identifiable, NSSecureCoding {
//        typealias Id = String
//        static let supportsSecureCoding: Bool = true
//
//        let encodingVersion: Int32
//
//        var id: Id { name }
//        let name: String
//        let positioning: StationPositioningType
//
//        let rootScan: ProjectScanRelation.PositionType
//        let secondScan: ProjectScanRelation.PositionType
//
//        let originRootStation: SurveyStation.Identifier
//        let originSecondaryStation: SurveyStation.Identifier
//
//        let radialRootStation: SurveyStation.Identifier
//        let radialSecondaryStation: SurveyStation.Identifier
//
//        required init?(coder decoder: NSCoder) {
//            let version = decoder.decodeInt32(forKey: PropertyKeys.version)
//            self.encodingVersion = version
//
//            if version == 1 {
//                self.name = decoder.decodeObject(
//                    forKey: PropertyKeys.name
//                ) as! String
//
//                let pos = decoder.decodeInt32(forKey: PropertyKeys.positioning)
//                self.positioning = StationPositioningType(rawValue: pos)!
//
//                self.rootScan = decoder.decodeInt32(forKey: PropertyKeys.rootScan)
//                self.secondScan = decoder.decodeInt32(
//                    forKey: PropertyKeys.secondScan)
//
//                self.originRootStation = decoder.decodeObject(
//                    of: NSUUID.self,
//                    forKey: PropertyKeys.originRootStation
//                )! as SurveyStation.Identifier
//                self.originSecondaryStation = decoder.decodeObject(
//                    of: NSUUID.self,
//                    forKey: PropertyKeys.originSecondaryStation
//                )! as SurveyStation.Identifier
//
//                self.radialRootStation = decoder.decodeObject(
//                    of: NSUUID.self,
//                    forKey: PropertyKeys.radialRootStation
//                )! as SurveyStation.Identifier
//                self.radialSecondaryStation = decoder.decodeObject(
//                    of: NSUUID.self,
//                    forKey: PropertyKeys.radialSecondaryStation
//                )! as SurveyStation.Identifier
//            } else {
//                fatalError("Unexpected encoding version \(version)")
//            }
//        }
//
//        func encode(with coder: NSCoder) {
//            coder.encode(ProjectFile.currentEncodingVersion,
//                         forKey: PropertyKeys.version)
//
//            coder.encode(name as NSString, forKey: PropertyKeys.name)
//            coder.encode(positioning.rawValue, forKey: PropertyKeys.positioning)
//            coder.encode(rootScan, forKey: PropertyKeys.rootScan)
//            coder.encode(secondScan, forKey: PropertyKeys.secondScan)
//            coder.encode(originRootStation,
//                         forKey: PropertyKeys.originRootStation)
//            coder.encode(originSecondaryStation,
//                         forKey: PropertyKeys.originSecondaryStation)
//            coder.encode(radialRootStation,
//                         forKey: PropertyKeys.radialRootStation)
//            coder.encode(radialSecondaryStation,
//                         forKey: PropertyKeys.radialSecondaryStation)
//
//        }
//
//        func calculateTransform() { }
//
//        private struct PropertyKeys {
//            static let version = "version"
//            static let name = "name"
//            static let positioning = "positioning"
//            static let rootScan = "rootScan"
//            static let secondScan = "secondScan"
//            static let originRootStation = "originRootStation"
//            static let originSecondaryStation = "originSecondaryStation"
//            static let radialRootStation = "radialRootStation"
//            static let radialSecondaryStation = "radialSecondaryStation"
//        }
//    }
}
