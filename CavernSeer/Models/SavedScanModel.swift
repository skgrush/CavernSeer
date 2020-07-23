//
//  SavedScanModel.swift
//  CavernSeer
//
//  Created by Samuel Grush on 6/20/20.
//  Copyright © 2020 Samuel K. Grush. All rights reserved.
//

import Foundation
import ARKit

/**
    Readonly model of a saved scan ready in from a file.
 */
struct SavedScanModel: Identifiable, Hashable, SavedStoredFileProtocol {
    /// the file basename, e.g. `scan_\(ISO8601-timestamp)`
    let id: String
    /// the URL the file was read from
    let url: URL
    /// the deserialized contents of the file
    let scan: ScanFile
    let fileSize: Int64

    init(url: URL) {
        self.url = url
        id = url.deletingPathExtension().lastPathComponent

        do {
            let data = try Data(contentsOf: url)
            self.fileSize = Int64(data.count)
            guard let scan = try NSKeyedUnarchiver.unarchivedObject(
                    ofClass: ScanFile.self,
                    from: data
                )
                else { fatalError("No ScanFile in archive") }
            self.scan = scan
        } catch {
            fatalError("Unable to read from url '\(url)', " +
                       "got error: \(error.localizedDescription)")
        }
    }

    func getURL() -> URL { url }

    #if DEBUG
    // Debug Initializer
    init(id: String, sysImage: String = "arkit") {
        self.id = id
        self.url = URL(string: "debug://\(id)")!
        self.scan = ScanFile(debugInit: nil)
        self.fileSize = 0
    }
    #endif
}
