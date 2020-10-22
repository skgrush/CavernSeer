//
//  ScanFile.swift
//  CavernSeer
//
//  Created by Samuel Grush on 6/21/20.
//  Copyright © 2020 Samuel K. Grush. All rights reserved.
//

import Foundation
import ARKit

final class ScanFile : NSObject, NSSecureCoding, StoredFileProtocol {
    static let fileExtension = "arscanfile"
    static let supportsSecureCoding: Bool = true
    static let dateFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withFullDate, .withFullTime]
        return f
    }()
    static let currentEncodingVersion: Int32 = 1

    let encodingVersion: Int32

    let timestamp: Date
    let name: String
    let center: simd_float3
    let extent: simd_float3
    let meshAnchors: [ARMeshAnchor]
    let startSnapshot: SnapshotAnchor?
    let endSnapshot: SnapshotAnchor?

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
        self.init(
            timestamp: date ?? Date(),
            center: map.center,
            extent: map.extent,
            /// pull out only the *true* ARMeshAnchors
            meshAnchors: map.anchors.compactMap {
                $0 is ARMeshAnchor ? $0 as? ARMeshAnchor : nil
            },
            startSnapshot: startSnap,
            endSnapshot: endSnap,
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

        if (version == 1) {
            guard
                let timestamp = decoder.decodeObject(
                    of: NSDate.self,
                    forKey: PropertyKeys.timestamp
                ) as Date?,
                let meshAnchors = decoder.decodeObject(
                    of: [NSArray.self, ARMeshAnchor.self],
                    forKey: PropertyKeys.meshAnchors
                ) as? [ARMeshAnchor]
            else { return nil }

            self.timestamp = timestamp as Date
            self.center =
                decoder.decode_simd_float3(prefix: PropertyKeys.center)
            self.extent =
                decoder.decode_simd_float3(prefix: PropertyKeys.extent)
            self.meshAnchors = meshAnchors

            if decoder.containsValue(forKey: PropertyKeys.name) {
                self.name = decoder.decodeObject(
                    forKey: PropertyKeys.name
                ) as! String
            } else {
                self.name = ScanFile.dateFormatter.string(from: self.timestamp)
            }

            if decoder.containsValue(forKey: PropertyKeys.startSnapshot) {
                self.startSnapshot = decoder.decodeObject(
                    of: SnapshotAnchor.self,
                    forKey: PropertyKeys.startSnapshot
                )
            } else {
                self.startSnapshot = nil
            }
            if decoder.containsValue(forKey: PropertyKeys.endSnapshot) {
                self.endSnapshot = decoder.decodeObject(
                    of: SnapshotAnchor.self,
                    forKey: PropertyKeys.endSnapshot
                )
            } else {
                self.endSnapshot = nil
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
        name: String? = nil,
        timestamp: Date = Date(),
        center: simd_float3,
        extent: simd_float3,
        meshAnchors: [ARMeshAnchor],
        startSnapshot: SnapshotAnchor?,
        endSnapshot: SnapshotAnchor?,
        stations: [SurveyStation],
        lines: [SurveyLine]
    ) {
        self.encodingVersion = ScanFile.currentEncodingVersion
        self.timestamp = timestamp
        self.name = name ?? ScanFile.dateFormatter.string(from: timestamp)
        self.center = center
        self.extent = extent
        self.meshAnchors = meshAnchors
        self.startSnapshot = startSnapshot
        self.endSnapshot = endSnapshot
        self.stations = stations
        self.lines = lines
    }

    func encode(with coder: NSCoder) {
        coder.encode(encodingVersion, forKey: PropertyKeys.version)
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

    func getTimestamp() -> Date { timestamp }

    #if DEBUG
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
