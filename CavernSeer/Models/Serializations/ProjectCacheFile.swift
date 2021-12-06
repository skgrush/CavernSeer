//
//  ProjectCacheFile.swift
//  CavernSeer
//
//  Created by Samuel Grush on 5/30/21.
//  Copyright © 2021 Samuel K. Grush. All rights reserved.
//

import Foundation

final class ProjectCacheFile : NSObject, NSSecureCoding, StoredCacheFileProtocol {
    static let filePrefix = "proj"
    static let fileExtension = "cavernseerproj-cache"
    static let supportsSecureCoding = true
    static let currentEncodingVersion: Int32 = 1

    let encodingVersion: Int32

    var id: String
    var timestamp: Date
    var displayName: String

    var realFileURL: URL?

    var jpegImageData: Data?

    init(realFileURL: URL, timestamp: Date, displayName: String, img: Data?) {
        self.encodingVersion = Self.currentEncodingVersion
        self.id = realFileURL.deletingPathExtension().lastPathComponent
        self.timestamp = timestamp
        self.displayName = displayName
        self.realFileURL = realFileURL
        self.jpegImageData = img
    }

    init?(coder decoder: NSCoder) {
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
                let name = decoder.decodeObject(
                    of: NSString.self,
                    forKey: PropertyKeys.name
                ) as String?,
                let realFileURL = decoder.decodeObject(
                    of: NSURL.self,
                    forKey: PropertyKeys.realFileURL
                ) as URL?
            else { return nil }

            self.timestamp = timestamp
            self.displayName = name
            self.realFileURL = realFileURL
            self.id = realFileURL.deletingPathExtension().lastPathComponent

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

        } else {
            fatalError("Unexpected encoding version \(version)")
        }
    }

    func encode(with coder: NSCoder) {
        coder.encode(encodingVersion, forKey: PropertyKeys.version)
        coder.encode(displayName, forKey: PropertyKeys.name)
        coder.encode(timestamp, forKey: PropertyKeys.timestamp)
        coder.encode(realFileURL, forKey: PropertyKeys.realFileURL)
        if jpegImageData != nil {
            coder.encode(jpegImageData, forKey: PropertyKeys.jpegImageData)
        }
    }


}

fileprivate struct PropertyKeys {
    static let version = "version"
    static let timestamp = "timestamp"
    static let name = "name"
    static let realFileURL = "realFileURL"
    static let jpegImageData = "jpegImageData"
}
