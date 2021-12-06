//
//  ScanFileTests.swift
//  CavernSeerTests
//
//  Created by Samuel Grush on 6/11/21.
//  Copyright © 2021 Samuel K. Grush. All rights reserved.
//

import XCTest
@testable import CavernSeer
import ARKit

class ScanFileTests : XCTestCase {

    /// M1/simulator can't decode many iOS-native AR* structures at all
    private let isMac = ProcessInfo.processInfo.isiOSAppOnMac

    // MARK: - Decoder tests -

    /**
     * Test for checking that we don't break backwards compatibility with v1 reading
     */
    func testDecodeV1() throws {
        try XCTSkipIf(isMac)

        // assemble
        let bundle = Bundle(for: type(of: self))
        guard let url = bundle.url(
                forResource: BeigeV1.filename,
                withExtension: "cavernseerscan"
        ) else {
            XCTFail("Missing test file: \(BeigeV1.filename).cavernseerscan")
            return
        }

        // act
        let data = try Data(contentsOf: url)

        let scan = try NSKeyedUnarchiver.unarchivedObject(
            ofClass: ScanFile.self,
            from: data
        )

        // assert
        XCTAssertNotNil(scan)
        try assertScan(scan: scan!, expected: BeigeV1.self)
    }

    /**
     * Test for checking that we're consistent with v2 reading
     */
    func testDecodeV2() throws {
        // assemble
        let bundle = Bundle(for: type(of: self))
        guard let url = bundle.url(
                forResource: GreenV2.filename,
                withExtension: "cavernseerscan"
        ) else {
            XCTFail("Missing test file: \(GreenV2.filename).cavernseerscan")
            return
        }

        // act
        let data = try Data(contentsOf: url)

        let scan = try NSKeyedUnarchiver.unarchivedObject(
            ofClass: ScanFile.self,
            from: data
        )

        // assert
        XCTAssertNotNil(scan)
        try assertScan(scan: scan!, expected: GreenV2.self)
    }


    // MARK: - Upgrade Tests -

    /**
     * Test for checking that we don't break backwards compatibility with v1 *upgrades* to v2
     */
    func testUpgradeV1ToV2() throws {
        try XCTSkipIf(ProcessInfo.processInfo.isiOSAppOnMac)

        // assemble
        let bundle = Bundle(for: type(of: self))
        guard let url = bundle.url(
                forResource: "beige_v1",
                withExtension: "cavernseerscan"
        ) else {
            XCTFail("Missing test file: beige_v1.cavernseerscan")
            return
        }

        let v1Data = try Data(contentsOf: url)
        let v1Scan = try NSKeyedUnarchiver.unarchivedObject(
            ofClass: ScanFile.self,
            from: v1Data
        )!

        // act (re-encode v1 to v2)
        let v2data = try NSKeyedArchiver.archivedData(
            withRootObject: v1Scan,
            requiringSecureCoding: true
        )
        let scan = try NSKeyedUnarchiver.unarchivedObject(
            ofClass: ScanFile.self,
            from: v2data
        )

        // assert (that it's still Beige *BUT* is now v2
        XCTAssertNotNil(scan)
        try assertScan(scan: scan!, expected: BeigeV1.self, v: 2)
    }


    private func assertScan<T : StaticScanFileTestData>(
        scan: ScanFile, expected: T.Type, v: Int32? = nil
    ) throws {
        let expectedVersion = v ?? expected.version

        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(secondsFromGMT: -300)
        formatter.dateFormat = "yyyy-MM-dd'T'HHmmssZ"
        let expectedDate = formatter.date(from: expected.dateString)!

        XCTAssertEqual(scan.encodingVersion, expectedVersion)
        XCTAssertLessThan(abs(expectedDate.distance(to: scan.timestamp)), 0.5)
        XCTAssertEqual(scan.name, expected.name)
        XCTAssertEqual(scan.center, expected.center)
        XCTAssertEqual(scan.extent, expected.extent)

        XCTAssertEqual(scan.meshAnchors.count, expected.meshCount)
        XCTAssertEqual(scan.meshAnchors[0].vertices.count, expected.mesh0Vertices)
        XCTAssertEqual(scan.meshAnchors[0].faces.count, expected.mesh0Faces)
        XCTAssertEqual(scan.meshAnchors[0].normals.count, expected.mesh0Normals)
        XCTAssertEqual(scan.meshAnchors[0].transform, expected.mesh0Tx)
        XCTAssertEqual(scan.startSnapshot?.name, "snapshot-start")
        XCTAssertEqual(scan.startSnapshot?.transform, expected.startTx)
        XCTAssertEqual(scan.startSnapshot?.imageData.count, expected.startSize)
        XCTAssertEqual(scan.startSnapshot?.identifier, expected.startUUID)
        XCTAssertNotNil(scan.endSnapshot)

        XCTAssertEqual(scan.stations.count, expected.stationCount)
        expected.stations.enumerated().forEach {
            (idx, expectedStation) in

            XCTAssertLessThan(idx, scan.stations.count)
            let actualStation = scan.stations[idx]
            let (expectedN, expectedId, expectedFirstCol) = expectedStation

            let expectedName = expectedN ?? expectedId.uuidString;
            XCTAssertEqual(actualStation.name, expectedName)
            XCTAssertEqual(actualStation.identifier, expectedId)
            XCTAssertEqual(actualStation.transform[0], expectedFirstCol)
        }
        let actualStationIds = scan.stations.map { $0.identifier }

        XCTAssertEqual(scan.lines.count, expected.lineCount)
        expected.lines.enumerated().forEach {
            (idx, expectedLine) in

            XCTAssertLessThan(idx, scan.lines.count)
            let actualLine = scan.lines[idx]
            let (expectedStart, expectedEnd) = expectedLine
            XCTAssertEqual(actualLine.startIdentifier, expectedStart)
            XCTAssertEqual(actualLine.endIdentifier, expectedEnd)

            XCTAssertTrue(actualStationIds.contains(expectedStart))
            XCTAssertTrue(actualStationIds.contains(expectedEnd))
        }
    }
}


protocol StaticScanFileTestData {
    static var filename: String { get }
    static var version: Int32 { get }
    static var dateString: String { get }
    static var name: String { get }
    static var center: simd_float3 { get }
    static var extent: simd_float3 { get }
    static var startTx: simd_float4x4 { get }
    static var startSize: Int { get }
    static var startUUID: UUID { get }

    static var meshCount: Int { get }
    static var mesh0Tx: simd_float4x4 { get }
    static var mesh0Vertices: Int { get }
    static var mesh0Faces: Int { get }
    static var mesh0Normals: Int { get }

    static var stationCount: Int { get }
    static var lineCount: Int { get }
    /// Simplified description of a `SurveyStation`, with the first row
    static var stations: [(String?, UUID, simd_float4)] { get }
    static var lines: [(UUID, UUID)] { get }
}

struct BeigeV1 : StaticScanFileTestData {
    static let filename = "beige_v1"
    static let version = Int32(1)
    static let dateString = "2021-06-11T214842-0500"
    static let name = "scan_2021-06-11T214842-0500"
    static let center = simd_make_float3(-0.36758095, -0.28897625, 0.036906123)
    static let extent = simd_make_float3( 0.71441650,  0.53990450, 0.471988260)
    static let startTx = simd_float4x4([
        [0.16495018, -0.9815927, 0.09626495, 0.0],
        [0.35363993, -0.03225161, -0.9348253, 0.0],
        [0.92072254, 0.18824275, 0.34181052, 0.0],
        [0.0051983777, 0.0014139581, 0.0032615997, 1.0]
    ])
    static let startSize = 158972
    static let startUUID = UUID(uuidString: "59A6E302-21BB-4DB4-91A0-BC922077104B")!

    static let meshCount = 4
    static let mesh0Tx = simd_float4x4([
        [0.95288026, 0.0, 0.30334637, 0.0],
        [0.0, 1.0, 0.0, 0.0],
        [-0.30334637, 0.0, 0.95288026, 0.0],
        [-0.20636876, -0.20152168, -0.03746107, 1.0]
    ])
    static let mesh0Vertices = 39
    static let mesh0Faces = 52
    static let mesh0Normals = 39

    static let stationCount = 0
    static let lineCount = 0
    static let stations: [(String?, UUID, simd_float4)] = []
    static let lines = [(UUID, UUID)]()
}

struct GreenV2 : StaticScanFileTestData {
    static let filename = "green_v2"
    static let version = Int32(2)
    static let dateString = "2021-12-05T203557-0600"
    static let name = "scan_greenly"
    static let center = simd_make_float3(-0.2989502, -0.65702164, 0.14327115)
    static let extent = simd_make_float3( 1.7053952,  1.27001600, 1.88892030)
    static let startTx = simd_float4x4([
        [0.41472444, -0.43204734, -0.80083627, 0.0],
        [-0.8816027, 0.027172042, -0.47120965, 0.0],
        [0.22534524, 0.9014416, -0.36962518, 0.0],
        [-0.0034897916, 0.0009838478, 0.009048734, 1.0000001]
    ])
    static let startSize = 194628
    static let startUUID = UUID(uuidString: "644CDBC7-7A08-432E-82B5-ACF9413BDC71")!

    static let meshCount = 2
    static let mesh0Tx = simd_float4x4([
        [0.51103294, 0.0, -0.85956115, 0.0],
        [0.0, 1.0, 0.0, 0.0],
        [0.85956115, 0.0, 0.51103294, 0.0],
        [0.018149931, -0.24505126, 0.027160278, 1.0]
    ])
    static let mesh0Vertices = 84
    static let mesh0Faces = 128
    static let mesh0Normals = 84

    static let stationCount = 2
    static let lineCount = 1
    /// Simplified description of a `SurveyStation`, with the first row
    static let stations: [(String?, UUID, simd_float4)] = [
        (nil, UUID(uuidString: "23C58D52-2535-4936-BA34-1727A643B21E")!, simd_float4(-0.9602766, 0.0, 0.27905017, 0.0)),
        (nil, UUID(uuidString: "E171F8A4-41F8-4616-AA18-C50F03D4310D")!, simd_float4(-0.8043165, -0.17596605, -0.56754804, 0.0)),
    ]
    static let lines: [(UUID, UUID)] = [
        (UUID(uuidString: "23C58D52-2535-4936-BA34-1727A643B21E")!, UUID(uuidString: "E171F8A4-41F8-4616-AA18-C50F03D4310D")!),
    ]
}
