//
//  ScanFile.swift
//  CavernSeer
//
//  Created by Samuel Grush on 6/21/20.
//  Copyright © 2020 Samuel K. Grush. All rights reserved.
//

import Foundation
import ARKit /// simd_float3, ARMeshAnchor, ARWorldMap

final class ScanFile : NSObject, NSSecureCoding, StoredFileProtocol {
    typealias CacheType = ScanCacheFile
    static let filePrefix = "scan"
    static let fileExtension = "cavernseerscan"
    static let supportsSecureCoding: Bool = true
    static let dateFormatter = getDefaultDateFormatter()
    /**
     * # V2 IS STILL EXPERIMENTAL
     *
     * v2 changed:
     *  - `meshAnchors` from `ARMeshAnchor` to `CSMeshSlice`
     *  - `*Snapshot`s from `SnapshotAnchor` to `CSMeshSnapshot`
     */
    static let currentEncodingVersion: Int32 = 2

    let encodingVersion: Int32

    let timestamp: Date
    let name: String
    let center: simd_float3
    let extent: simd_float3
    let meshAnchors: [CSMeshSlice]
    let startSnapshot: CSMeshSnapshot?
    let endSnapshot: CSMeshSnapshot?

    let stations: [SurveyStation]
    let lines: [SurveyLine]

    convenience init(
        map: ARWorldMap,
        name: String? = nil,
        startSnap: SnapshotAnchor?,
        endSnap: SnapshotAnchor?,
        date: Date?,
        stations: [SurveyStationEntity],
        lines: [SurveyLineEntity]
    ) {
        let timestamp = date ?? Date()
        self.init(
            name: name ?? Self.makeDefaultBaseName(
                with: timestamp,
                as: Self.dateFormatter
            ),
            timestamp: timestamp,
            center: map.center,
            extent: map.extent,
            /// pull out only the *true* ARMeshAnchors
            meshAnchors: map.anchors
                .compactMap { $0 as? ARMeshAnchor }
                .map { CSMeshSlice(anchor: $0) },
            startSnapshot: CSMeshSnapshot.failableInit(snapshot: startSnap),
            endSnapshot: CSMeshSnapshot.failableInit(snapshot: endSnap),
            stations: stations.map { SurveyStation(entity: $0) },
            lines: lines.map { SurveyLine(entity: $0) }
        )
    }

    required init?(coder decoder: NSCoder) {

        let version =
            decoder.containsValue(forKey: PropertyKeys.version)
                ? decoder.decodeInt32(forKey: PropertyKeys.version)
                : 1
        self.encodingVersion = version

        if (version == 1 || version == 2) {
            guard
                let timestamp = decoder.decodeObject(
                    of: NSDate.self,
                    forKey: PropertyKeys.timestamp
                ) as Date?
            else { return nil }

            self.timestamp = timestamp as Date
            self.center =
                decoder.decode_simd_float3(prefix: PropertyKeys.center)
            self.extent =
                decoder.decode_simd_float3(prefix: PropertyKeys.extent)

            if version == 1 {
                guard
                    let meshAnchors = decoder.decodeObject(
                        of: [NSArray.self, ARMeshAnchor.self],
                        forKey: PropertyKeys.meshAnchors
                    ) as? [ARMeshAnchor]
                else { return nil }
                self.meshAnchors = meshAnchors.map { CSMeshSlice(anchor: $0) }

                if decoder.containsValue(forKey: PropertyKeys.startSnapshot) {
                    self.startSnapshot = CSMeshSnapshot.failableInit(
                        snapshot: decoder.decodeObject(
                            of: SnapshotAnchor.self,
                            forKey: PropertyKeys.startSnapshot
                        )
                    )
                } else {
                    self.startSnapshot = nil
                }
                if decoder.containsValue(forKey: PropertyKeys.endSnapshot) {
                    self.endSnapshot = CSMeshSnapshot.failableInit(
                        snapshot: decoder.decodeObject(
                            of: SnapshotAnchor.self,
                            forKey: PropertyKeys.endSnapshot
                        )
                    )
                } else {
                    self.endSnapshot = nil
                }
            } else {
                guard
                    let meshAnchors = decoder.decodeObject(
                        of: [NSArray.self, CSMeshSlice.self],
                        forKey: PropertyKeys.meshAnchors
                    ) as? [CSMeshSlice]
                else { return nil }
                self.meshAnchors = meshAnchors

                if decoder.containsValue(forKey: PropertyKeys.startSnapshot) {
                    self.startSnapshot = decoder.decodeObject(
                        of: CSMeshSnapshot.self,
                        forKey: PropertyKeys.startSnapshot
                    )
                } else {
                    self.startSnapshot = nil
                }
                if decoder.containsValue(forKey: PropertyKeys.endSnapshot) {
                    self.endSnapshot = decoder.decodeObject(
                        of: CSMeshSnapshot.self,
                        forKey: PropertyKeys.endSnapshot
                    )
                } else {
                    self.endSnapshot = nil
                }
            }

            if decoder.containsValue(forKey: PropertyKeys.name) {
                self.name = decoder.decodeObject(
                    forKey: PropertyKeys.name
                ) as! String
            } else {
                self.name = ScanFile.makeDefaultBaseName(
                    with: self.timestamp,
                    as: ScanFile.dateFormatter
                )
                debugPrint("ScanFile \(self.name) missing name in archive")
            }

            if decoder.containsValue(forKey: PropertyKeys.stations) {
                self.stations = decoder.decodeObject(
                    of: [NSArray.self, SurveyStation.self],
                    forKey: PropertyKeys.stations
                ) as! [SurveyStation]
            } else {
                self.stations = []
            }
            if decoder.containsValue(forKey: PropertyKeys.lines) {
                self.lines = decoder.decodeObject(
                    of: [NSArray.self, SurveyLine.self],
                    forKey: PropertyKeys.lines
                ) as! [SurveyLine]
            } else {
                self.lines = []
            }
        } else {
            fatalError("Unexpected encoding version \(version)")
        }
    }


    internal init(
        name: String,
        timestamp: Date,
        center: simd_float3,
        extent: simd_float3,
        meshAnchors: [CSMeshSlice],
        startSnapshot: CSMeshSnapshot?,
        endSnapshot: CSMeshSnapshot?,
        stations: [SurveyStation],
        lines: [SurveyLine]
    ) {
        self.encodingVersion = ScanFile.currentEncodingVersion
        self.timestamp = timestamp
        self.name = name
        self.center = center
        self.extent = extent
        self.meshAnchors = meshAnchors
        self.startSnapshot = startSnapshot
        self.endSnapshot = endSnapshot
        self.stations = stations
        self.lines = lines
    }

    func encode(with coder: NSCoder) {
        coder.encode(Self.currentEncodingVersion, forKey: PropertyKeys.version)
        coder.encode(name, forKey: PropertyKeys.name)
        coder.encode(timestamp, forKey: PropertyKeys.timestamp)
        coder.encode(center, forPrefix: PropertyKeys.center)
        coder.encode(extent, forPrefix: PropertyKeys.extent)
        coder.encode(meshAnchors as NSArray, forKey: PropertyKeys.meshAnchors)
        coder.encode(startSnapshot, forKey: PropertyKeys.startSnapshot)
        coder.encode(endSnapshot, forKey: PropertyKeys.endSnapshot)

        coder.encode(stations as NSArray, forKey: PropertyKeys.stations)
        coder.encode(lines as NSArray, forKey: PropertyKeys.lines)
    }

    #if DEBUG
    /** DEBUG only constructor */
    init(debugInit: Any?) {
        self.encodingVersion = ScanFile.currentEncodingVersion

        self.timestamp = Date()
        self.name = ScanFile.dateFormatter.string(from: self.timestamp)
        self.center = simd_make_float3(0)
        self.extent = simd_make_float3(0)
        self.meshAnchors = []
        self.startSnapshot = nil
        self.endSnapshot = nil

        self.lines = []
        self.stations = []

        super.init()
    }
    #endif

    func createCacheFile(thisFileURL: URL) -> ScanCacheFile {
        // compress the image if we can
        var img = startSnapshot?.imageData
        if img != nil {
            let uiImg = UIImage(data: img!)
            // in case UIImage processing or compression fails, fall back to img
            img = uiImg?.jpegData(compressionQuality: 0.2) ?? img
        }
        return ScanCacheFile(
            realFileURL: thisFileURL,
            timestamp: timestamp,
            displayName: name,
            img: img
        )
    }
}


fileprivate struct PropertyKeys {
    static let version = "version"
    static let name = "name"
    static let timestamp = "timestamp"
    static let center = "center"
    static let extent = "extent"
    static let meshAnchors = "meshAnchors"
    static let startSnapshot = "startSnapshot"
    static let endSnapshot = "endSnapshot"
    static let stations = "stations"
    static let lines = "lines"

}
