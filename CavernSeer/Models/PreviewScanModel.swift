//
//  PreviewScanModel.swift
//  CavernSeer
//
//  Created by Samuel Grush on 12/30/20.
//  Copyright © 2020 Samuel K. Grush. All rights reserved.
//

import Foundation

struct PreviewScanModel: Identifiable, Hashable, PreviewStoredFileProtocol {

    let id: String
    let url: URL

    let name: String

    let fileSize: Int64

    let imageData: Data?

    init(url: URL) throws {
        self.url = url
        self.id = url.deletingPathExtension().lastPathComponent

        let data = try Data(contentsOf: url)
        self.fileSize = Int64(data.count)
        guard let scan = try NSKeyedUnarchiver.unarchivedObject(
                ofClass: ScanFile.self,
                from: data
            )
        else { throw FileOpenError.noFileInArchive(url: url) }

        self.name = scan.name
        self.imageData = scan.startSnapshot?.imageData
    }
}
