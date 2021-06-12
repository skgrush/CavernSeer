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

    let beigeDateString = "2021-06-11T214842-0500"
    let beigeName = "scan_2021-06-11T214842-0500"
    let beigeCenter = simd_make_float3(-0.36758095, -0.28897625, 0.036906123)
    let beigeExtent = simd_make_float3( 0.71441650,  0.53990450, 0.471988260)
    let beigeStartTx = simd_float4x4([
        [0.16495018, -0.9815927, 0.09626495, 0.0],
        [0.35363993, -0.03225161, -0.9348253, 0.0],
        [0.92072254, 0.18824275, 0.34181052, 0.0],
        [0.0051983777, 0.0014139581, 0.0032615997, 1.0]
    ])
    let beigeStartSize = 158972
    let beigeStartUUID = UUID(uuidString: "59A6E302-21BB-4DB4-91A0-BC922077104B")
    let beigeMesh0Tx = simd_float4x4([
        [0.95288026, 0.0, 0.30334637, 0.0],
        [0.0, 1.0, 0.0, 0.0],
        [-0.30334637, 0.0, 0.95288026, 0.0],
        [-0.20636876, -0.20152168, -0.03746107, 1.0]
    ])

    /**
     * Test for checking that we don't break backwards compatibility with v1 reading
     */
    func testDecodeV1() throws {
        // assemble
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(secondsFromGMT: -300)
        formatter.dateFormat = "yyyy-MM-dd'T'HHmmssZ"
        let expectedDate = formatter.date(from: beigeDateString)!


        let bundle = Bundle(for: type(of: self))
        guard let url = bundle.url(
                forResource: "beige_v1",
                withExtension: "cavernseerscan"
        ) else {
            XCTFail("Missing test file: beige_v1.cavernseerscan")
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
        XCTAssertEqual(scan!.encodingVersion, 1)
        XCTAssertLessThan(expectedDate.distance(to: scan!.timestamp), 0.5)
        XCTAssertEqual(scan!.name, beigeName)
        XCTAssertEqual(scan!.center, beigeCenter)
        XCTAssertEqual(scan!.extent, beigeExtent)
        XCTAssertEqual(scan!.meshAnchors.count, 4)
        XCTAssertEqual(scan!.meshAnchors[0].vertices.count, 39)
        XCTAssertEqual(scan!.meshAnchors[0].faces.count, 52)
        XCTAssertEqual(scan!.meshAnchors[0].transform, beigeMesh0Tx)
        XCTAssertEqual(scan!.startSnapshot?.name, "snapshot-start")
        XCTAssertEqual(scan!.startSnapshot?.transform, beigeStartTx)
        XCTAssertEqual(scan!.startSnapshot?.imageData.count, beigeStartSize)
        XCTAssertEqual(scan!.startSnapshot?.identifier, beigeStartUUID)
        XCTAssertNotNil(scan!.endSnapshot)
        XCTAssertEqual(scan!.stations.count, 0)
        XCTAssertEqual(scan!.lines.count, 0)
    }

    /**
     * Test for checking that we don't break backwards compatibility with v1 *upgrades* to v2
     */
    func testUpgradeV1ToV2() throws {
        // assemble
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(secondsFromGMT: -300)
        formatter.dateFormat = "yyyy-MM-dd'T'HHmmssZ"
        let expectedDate = formatter.date(from: beigeDateString)!

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

        // act
        let v2data = try NSKeyedArchiver.archivedData(
            withRootObject: v1Scan,
            requiringSecureCoding: true
        )
        let scan = try NSKeyedUnarchiver.unarchivedObject(
            ofClass: ScanFile.self,
            from: v2data
        )

        // assert
        XCTAssertNotNil(scan)
        XCTAssertEqual(scan!.encodingVersion, 2)
        XCTAssertLessThan(expectedDate.distance(to: scan!.timestamp), 0.5)
        XCTAssertEqual(scan!.name, beigeName)
        XCTAssertEqual(scan!.center, beigeCenter)
        XCTAssertEqual(scan!.extent, beigeExtent)
        XCTAssertEqual(scan!.meshAnchors.count, 4)
        XCTAssertEqual(scan!.meshAnchors[0].vertices.count, 39)
        XCTAssertEqual(scan!.meshAnchors[0].faces.count, 52)
        XCTAssertEqual(scan!.meshAnchors[0].transform, beigeMesh0Tx)
        XCTAssertEqual(scan!.startSnapshot?.name, "snapshot-start")
        XCTAssertEqual(scan!.startSnapshot?.transform, beigeStartTx)
        XCTAssertEqual(scan!.startSnapshot?.imageData.count, beigeStartSize)
        XCTAssertEqual(scan!.startSnapshot?.identifier, beigeStartUUID)
        XCTAssertNotNil(scan!.endSnapshot)
        XCTAssertEqual(scan!.stations.count, 0)
        XCTAssertEqual(scan!.lines.count, 0)
    }
}
