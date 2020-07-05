//
//  ScanFile.swift
//  CavernSeer
//
//  Created by Samuel Grush on 6/21/20.
//  Copyright © 2020 Samuel K. Grush. All rights reserved.
//

import Foundation
import ARKit

final class ScanFile : NSObject, NSSecureCoding {
    static var supportsSecureCoding: Bool {
        true
    }

    let timestamp: Date
    let center: simd_float3
    let extent: simd_float3
    let meshAnchors: [ARMeshAnchor]
    let startSnapshot: SnapshotAnchor?
    let endSnapshot: SnapshotAnchor?

    let stations: [SurveyStation]
    let lines: [SurveyLine]

    init(
        map: ARWorldMap,
        startSnap: SnapshotAnchor?,
        endSnap: SnapshotAnchor?,
        date: Date?,
        stations: [SurveyStationEntity],
        lines: [SurveyLineEntity]
    ) {
        self.timestamp = date ?? Date()
        self.center = map.center
        self.extent = map.extent
        // pull out only the ARMeshAnchors
        self.meshAnchors = map.anchors.compactMap {
            $0 is ARMeshAnchor ? $0 as? ARMeshAnchor : nil
        }
        self.startSnapshot = startSnap
        self.endSnapshot = endSnap

        self.stations = stations.map { SurveyStation(entity: $0) }
        self.lines = lines.map { SurveyLine(entity: $0) }
    }

    required init?(coder decoder: NSCoder) {
        guard
            let timestamp = decoder.decodeObject(
                of: NSDate.self,
                forKey: "timestamp"
            ) as Date?,
            let meshAnchors = decoder.decodeObject(
                of: [NSArray.self, ARMeshAnchor.self],
                forKey: "meshAnchors"
            ) as? [ARMeshAnchor]
        else { return nil }

        self.timestamp = timestamp as Date
        self.center = decoder.decode_simd_float3(prefix: "center")
        self.extent = decoder.decode_simd_float3(prefix: "extent")
        self.meshAnchors = meshAnchors

        if decoder.containsValue(forKey: "startSnapshot") {
            self.startSnapshot = decoder.decodeObject(
                of: SnapshotAnchor.self,
                forKey: "startSnapshot"
            )
        } else {
            self.startSnapshot = nil
        }
        if decoder.containsValue(forKey: "endSnapshot") {
            self.endSnapshot = decoder.decodeObject(
                of: SnapshotAnchor.self,
                forKey: "endSnapshot"
            )
        } else {
            self.endSnapshot = nil
        }

        if decoder.containsValue(forKey: "stations") {
            self.stations = decoder.decodeObject(
                of: [NSArray.self, SurveyStation.self],
                forKey: "stations"
            ) as! [SurveyStation]
        } else {
            self.stations = []
        }
        if decoder.containsValue(forKey: "lines") {
            self.lines = decoder.decodeObject(
                of: [NSArray.self, SurveyLine.self],
                forKey: "lines"
            ) as! [SurveyLine]
        } else {
            self.lines = []
        }
    }

    func encode(with coder: NSCoder) {
        coder.encode(timestamp, forKey: "timestamp")
        coder.encode(center, forPrefix: "center")
        coder.encode(extent, forPrefix: "extent")
        coder.encode(meshAnchors as NSArray, forKey: "meshAnchors")
        coder.encode(startSnapshot, forKey: "startSnapshot")
        coder.encode(endSnapshot, forKey: "endSnapshot")

        coder.encode(stations as NSArray, forKey: "stations")
        coder.encode(lines as NSArray, forKey: "lines")
    }

    #if DEBUG
    init(debugInit: Any?) {
        self.timestamp = Date()
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
