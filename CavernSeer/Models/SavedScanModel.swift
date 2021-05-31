//
//  SavedScanModel.swift
//  CavernSeer
//
//  Created by Samuel Grush on 6/20/20.
//  Copyright © 2020 Samuel K. Grush. All rights reserved.
//

import Foundation

/**
    Readonly model of a saved scan ready in from a file.
 */
struct SavedScanModel: Identifiable, Hashable, SavedStoredFileProtocol {
    typealias FileType = ScanFile

    /// the file name, e.g. `scan_\(ISO8601-timestamp)` (no extension)
    let id: String
    /// the URL the file was read from
    let url: URL
    /// the deserialized contents of the file
    let scan: ScanFile
    let fileSize: Int64

    init(url: URL) throws {
        self.url = url
        id = url.deletingPathExtension().lastPathComponent

        let data = try Data(contentsOf: url)
        self.fileSize = Int64(data.count)
        guard let scan = try NSKeyedUnarchiver.unarchivedObject(
                ofClass: ScanFile.self,
                from: data
            )
        else { throw FileOpenError.noFileInArchive(url: url) }
        self.scan = scan
    }

    func getURL() -> URL { url }
    func getFile() -> FileType { scan }

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
