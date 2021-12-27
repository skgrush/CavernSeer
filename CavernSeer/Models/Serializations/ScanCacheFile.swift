//
//  ScanCacheFile.swift
//  CavernSeer
//
//  Created by Samuel Grush on 5/29/21.
//  Copyright © 2021 Samuel K. Grush. All rights reserved.
//

import Foundation

final class ScanCacheFile : NSObject, NSSecureCoding, StoredCacheFileProtocol {

    static let filePrefix = "scan"
    static let fileExtension = "cavernseerscan-cache"
    static let supportsSecureCoding = true
    static let currentEncodingVersion: Int32 = 1

    let encodingVersion: Int32

    let id: String
    let timestamp: Date
    let displayName: String
    let error: Error?

    var searchableText: String = ""
    var realFileURL: URL? = nil

    let jpegImageData: Data?

    init(realFileURL: URL, timestamp: Date, displayName: String, img: Data?, error: Error? = nil) {
        self.encodingVersion = Self.currentEncodingVersion
        self.id = realFileURL.deletingPathExtension().lastPathComponent
        self.timestamp = timestamp
        self.displayName = displayName
        self.realFileURL = realFileURL
        self.jpegImageData = img
        self.error = error

        super.init()

        self.searchableText = getSearchableText()
    }

    required init?(coder decoder: NSCoder) {

        let version =
            decoder.containsValue(forKey: PropertyKeys.version)
                ? decoder.decodeInt32(forKey: PropertyKeys.version)
                : 1
        self.encodingVersion = version
        self.error = nil

        if (version == 1) {
            guard
                let timestamp = decoder.decodeObject(
                    of: NSDate.self,
                    forKey: PropertyKeys.timestamp
                ) as Date?,
                let name = decoder.decodeObject(
                    of: NSString.self,
                    forKey: PropertyKeys.name
                ) as String?,
                let id = decoder.decodeObject(
                    of: NSString.self,
                    forKey: PropertyKeys.id
                ) as String?
            else { return nil }

            self.timestamp = timestamp
            self.displayName = name
            self.id = id

            if decoder.containsValue(forKey: PropertyKeys.jpegImageData) {
                guard
                    let jpegImageData = decoder.decodeObject(
                        of: NSData.self,
                        forKey: PropertyKeys.jpegImageData
                    ) as Data?
                else { return nil }
                self.jpegImageData = jpegImageData
            } else {
                self.jpegImageData = nil
            }

            super.init()

            self.searchableText = getSearchableText()

        } else {
            fatalError("Unexpected encoding version \(version)")
        }
    }

    func encode(with coder: NSCoder) {
        coder.encode(encodingVersion, forKey: PropertyKeys.version)
        coder.encode(displayName, forKey: PropertyKeys.name)
        coder.encode(timestamp, forKey: PropertyKeys.timestamp)
        coder.encode(id, forKey: PropertyKeys.id)
        if jpegImageData != nil {
            coder.encode(jpegImageData, forKey: PropertyKeys.jpegImageData)
        }
    }

    private func getSearchableText() -> String {
        return [
            displayName,
            timestamp.formatted(date: .long, time: .omitted)
        ]
            .joined(separator: "\u{0}")
            .lowercased()
    }

    #if DEBUG
    // Debug Initializer
    init(id: String, sysImage: String = "arkit") {
        self.id = id
        self.realFileURL = URL(string: "debug://\(id)")!
        self.displayName = id
        self.encodingVersion = Self.currentEncodingVersion
        self.jpegImageData = nil
        self.error = nil
        self.timestamp = Date()
    }
    #endif
}

fileprivate struct PropertyKeys {
    static let version = "version"
    static let id = "id"
    static let timestamp = "timestamp"
    static let name = "name"
    static let jpegImageData = "jpegImageData"
}
