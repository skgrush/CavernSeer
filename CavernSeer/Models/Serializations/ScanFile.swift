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

    /// the version this ScanFile was encoded for. Note that it must still have the current structure.
    let encodingVersion: Int32

    /// Timestamp, including timezone, of the original scan.
    let timestamp: Date
    /// Name for the scan, encoded into the file and distinct from the filename. Initially `scan_\(timestamp)`
    let name: String
    let center: simd_float3
    let extent: simd_float3
    let meshAnchors: [CSMeshSlice]
    let startSnapshot: CSMeshSnapshot?
    let endSnapshot: CSMeshSnapshot?

    let stations: [SurveyStation]
    let lines: [SurveyLine]

    let location: CSLocation?

    /**
     * Initializer from an `ARWorldMap` state and `AR` structures during scanning.
     */
    convenience init(
        map: ARWorldMap,
        name: String? = nil,
        startSnap: SnapshotAnchor?,
        endSnap: SnapshotAnchor?,
        date: Date = Date(),
        stations: [SurveyStationEntity],
        lines: [SurveyLineEntity],
        location: CLLocation?
    ) {
        self.init(
            name: name ?? Self.makeDefaultBaseName(
                with: date,
                as: Self.dateFormatter
            ),
            timestamp: date,
            center: map.center,
            extent: map.extent,
            /// pull out only the *true* ARMeshAnchors
            meshAnchors: map.anchors
                .compactMap { $0 as? ARMeshAnchor }
                .map { CSMeshSlice(anchor: $0) },
            startSnapshot: startSnap.map { CSMeshSnapshot(snapshot: $0) },
            endSnapshot: endSnap.map { CSMeshSnapshot(snapshot: $0) },
            stations: stations.map { SurveyStation(entity: $0) },
            lines: lines.map { SurveyLine(entity: $0) },
            location: location.map { CSLocation(loc: $0, manual: false) }
        )
    }

    required init?(coder: NSCoder) {

        let decoder = Decode(coder: coder)
        self.encodingVersion = decoder.version

        do {
            self.timestamp = try decoder.timestamp()
            self.name = try decoder.name(timestamp: self.timestamp)
            self.center = decoder.center()
            self.extent = decoder.extent()
            self.meshAnchors = try decoder.meshAnchors()
            self.startSnapshot =
                try decoder.snapshot(key: PropertyKeys.startSnapshot)
            self.endSnapshot =
                try decoder.snapshot(key: PropertyKeys.endSnapshot)
            self.stations = try decoder.stations()
            self.lines = try decoder.lines()
            self.location = try decoder.location()
        } catch DecodeError.badVersion {
            debugPrint("Bad version \(decoder.version)")
            return nil
        } catch DecodeError.castFailure(let property) {
            debugPrint("Failed to cast \(property)")
            return nil
        } catch DecodeError.missingMandatory(let property) {
            debugPrint("Missing mandatory key \(property)")
            return nil
        } catch {
            debugPrint("Unknown failure encoding; \(error)")
            return nil
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
        lines: [SurveyLine],
        location: CSLocation?
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
        self.location = location
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

        coder.encode(location, forKey: PropertyKeys.location)
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

        self.location = nil

        super.init()
    }
    #endif

    /**
     * Create a `ScanCacheFile` describing this `ScanFile`.
     * Image is compressed before storing.
     */
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

extension ScanFile {
    struct PropertyKeys {
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
        static let location = "location"
    }


    /**
     * Property decoders for `ScanFile`.
     *
     * Initializer stores the coder and decodes/stores the version for use in other decoders.
     * Decoder methods can throw `DecodeError`s.
     */
    struct Decode {
        let version: Int32
        let decoder: NSCoder

        init(coder: NSCoder) {
            decoder = coder
            version =
                decoder.containsValue(forKey: PropertyKeys.version)
                    ? decoder.decodeInt32(forKey: PropertyKeys.version)
                    : 1
        }

        func name(timestamp: Date) throws -> String {
            if decoder.containsValue(forKey: PropertyKeys.name) {
                if
                    let name = decoder.decodeObject(
                        forKey: PropertyKeys.name
                    ) as? String
                {
                    return name
                } else {
                    throw DecodeError.castFailure(property: "name")
                }
            } else {
                let name = ScanFile.makeDefaultBaseName(
                    with: timestamp,
                    as: ScanFile.dateFormatter
                )
                debugPrint("ScanFile \(name) missing name in archive")
                return name
            }
        }

        func timestamp() throws -> Date {
            try throwIfMissing(key: PropertyKeys.timestamp)
            if
                let date = decoder.decodeObject(
                    of: NSDate.self,
                    forKey: PropertyKeys.timestamp
                ) as Date?
            {
                return date
            } else {
                throw DecodeError.castFailure(property: "date")
            }
        }

        func center() -> simd_float3 {
            return decoder.decode_simd_float3(prefix: PropertyKeys.center)
        }

        func extent() -> simd_float3 {
            decoder.decode_simd_float3(prefix: PropertyKeys.extent)
        }

        func meshAnchors() throws -> [CSMeshSlice] {
            try throwIfMissing(key: PropertyKeys.meshAnchors)
            switch version {
                case 1:
                    if let meshes = decoder.decodeObject(
                        of: [NSArray.self, ARMeshAnchor.self],
                        forKey: PropertyKeys.meshAnchors
                    ) as? [ARMeshAnchor] {
                        return meshes.map { CSMeshSlice(anchor: $0) }
                    } else {
                        throw DecodeError.castFailure(property: "meshes")
                    }

                case 2:
                    if let meshes = decoder.decodeObject(
                        of: [NSArray.self, CSMeshSlice.self],
                        forKey: PropertyKeys.meshAnchors
                    ) as? [CSMeshSlice] {
                        return meshes
                    } else {
                        throw DecodeError.castFailure(property: "meshes")
                    }
                default:
                    fatalError("Unexpected encoding version \(version)")
            }
        }

        func snapshot(key: String) throws -> CSMeshSnapshot? {
            if decoder.containsValue(forKey: key) {
                let snapshot: CSMeshSnapshot?
                switch version {
                    case 1:
                        snapshot = decoder.decodeObject(
                            of: SnapshotAnchor.self,
                            forKey: key
                        ).map { CSMeshSnapshot(snapshot: $0) }
                    case 2:
                        snapshot = decoder.decodeObject(
                            of: CSMeshSnapshot.self,
                            forKey: key
                        )
                    default:
                        throw DecodeError.badVersion
                }
                if snapshot != nil {
                    return snapshot!
                } else {
                    throw DecodeError.castFailure(property: key)
                }
            } else {
                return nil
            }
        }

        func stations() throws -> [SurveyStation] {
            if decoder.containsValue(forKey: PropertyKeys.stations) {
                if
                    let stations = decoder.decodeObject(
                        of: [NSArray.self, SurveyStation.self],
                        forKey: PropertyKeys.stations
                    ) as? [SurveyStation]
                {
                    return stations
                } else {
                    throw DecodeError.castFailure(property: "stations")
                }
            } else {
                return []
            }
        }

        func lines() throws -> [SurveyLine] {
            if decoder.containsValue(forKey: PropertyKeys.lines) {
                if
                    let lines = decoder.decodeObject(
                        of: [NSArray.self, SurveyLine.self],
                        forKey: PropertyKeys.lines
                    ) as? [SurveyLine]
                {
                    return lines
                } else {
                    throw DecodeError.castFailure(property: "lines")
                }
            } else {
                return []
            }
        }

        func location() throws -> CSLocation? {
            if decoder.containsValue(forKey: PropertyKeys.location) {
                return decoder.decodeObject(
                    of: CSLocation.self,
                    forKey: PropertyKeys.location
                )
            } else {
                return nil
            }
        }

        private func throwIfMissing(key: String) throws {
            if !decoder.containsValue(forKey: key) {
                throw DecodeError.missingMandatory(property: key)
            }
        }
    }

    enum DecodeError : Error {
        case castFailure(property: String)
        case missingMandatory(property: String)
        case badVersion
    }
}
