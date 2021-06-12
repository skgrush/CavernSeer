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
        XCTAssertEqual(scan.meshAnchors[0].transform, expected.mesh0Tx)
        XCTAssertEqual(scan.startSnapshot?.name, "snapshot-start")
        XCTAssertEqual(scan.startSnapshot?.transform, expected.startTx)
        XCTAssertEqual(scan.startSnapshot?.imageData.count, expected.startSize)
        XCTAssertEqual(scan.startSnapshot?.identifier, expected.startUUID)
        XCTAssertNotNil(scan.endSnapshot)
        XCTAssertEqual(scan.stations.count, expected.stationCount)
        XCTAssertEqual(scan.lines.count, expected.lineCount)
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
    static var stationCount: Int { get }
    static var lineCount: Int { get }
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
    static let stationCount = 0
    static let lineCount = 0
}

struct GreenV2 : StaticScanFileTestData {
    static let filename = "green_v2"
    static let version = Int32(2)
    static let dateString = "2021-06-12T093735-0500"
    static let name = "scan_\(dateString)"
    static let center = simd_make_float3(-0.16800843, -0.03744083, -0.15262002)
    static let extent = simd_make_float3( 0.30835554,  0.20957838,  0.32511657)
    static let startTx = simd_float4x4([
        [0.6284522, 0.0037705249, -0.777839, 0.0],
        [-0.39420128, 0.8636067, -0.3143072, 0.0],
        [0.6705619, 0.5041522, 0.5442219, 0.0],
        [-0.00054637936, 0.0015081065, 0.0008383893, 1.0000001]
    ])
    static let startSize = 166149
    static let startUUID = UUID(uuidString: "A8C974ED-87CB-45DE-AF09-65E239EE5CB3")!

    static let meshCount = 2
    static let mesh0Tx = simd_float4x4([
        [0.6049775, 0.0, -0.7962426, 0.0],
        [0.0, 1.0, 0.0, 0.0],
        [0.7962426, 0.0, 0.6049775, 0.0],
        [-0.057474896, -0.15222016, -0.19562788, 1.0]
    ])
    static let mesh0Vertices = 40
    static let mesh0Faces = 55
    static let stationCount = 0
    static let lineCount = 0
}
