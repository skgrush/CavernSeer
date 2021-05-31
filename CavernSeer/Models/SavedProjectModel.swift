//
//  SavedProjectModel.swift
//  CavernSeer
//
//  Created by Samuel Grush on 7/22/20.
//  Copyright © 2020 Samuel K. Grush. All rights reserved.
//

import Foundation

/**
    Readonly model of a saved project read in from a file.
 */
struct SavedProjectModel: Identifiable, Hashable, SavedStoredFileProtocol {
    typealias FileType = ProjectFile

    /// the file basename, e.g. `proj_\(ISO8601-timestamp)`
    let id: String
    /// the URL the file was read from
    let url: URL
    /// the deserialized contents of the file
    let project: ProjectFile
    let fileSize: Int64

    init(url: URL) throws {
        self.url = url
        id = url.deletingPathExtension().lastPathComponent

        let data = try Data(contentsOf: url)
        self.fileSize = Int64(data.count)
        guard let project = try NSKeyedUnarchiver.unarchivedObject(
                ofClass: ProjectFile.self,
                from: data)
        else { throw FileOpenError.noFileInArchive(url: url) }
        self.project = project
    }

    func getURL() -> URL { url }
    func getFile() -> FileType { project }
}
