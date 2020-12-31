//
//  PreviewProjectModel.swift
//  CavernSeer
//
//  Created by Samuel Grush on 12/30/20.
//  Copyright © 2020 Samuel K. Grush. All rights reserved.
//

import Foundation

struct PreviewProjectModel: Identifiable, Hashable, PreviewStoredFileProtocol {

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
        guard let project = try NSKeyedUnarchiver.unarchivedObject(
                ofClass: ProjectFile.self,
                from: data
            )
        else { throw FileOpenError.noFileInArchive(url: url) }

        self.name = project.name
        self.imageData = project.scans.first?.scan.startSnapshot?.imageData

    }
}
