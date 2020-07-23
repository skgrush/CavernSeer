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
    /// the file basename, e.g. `proj_\(ISO8601-timestamp)`
    let id: String
    /// the URL the file was read from
    let url: URL
    /// the deserialized contents of the file
    let project: ProjectFile
    let fileSize: Int64

    init(url: URL) {
        self.url = url
        id = url.deletingPathExtension().lastPathComponent

        do {
            let data = try Data(contentsOf: url)
            self.fileSize = Int64(data.count)
            guard let project = try NSKeyedUnarchiver.unarchivedObject(
                    ofClass: ProjectFile.self,
                    from: data)
            else { fatalError("No ProjectFile in archive") }
            self.project = project
        } catch {
            fatalError("Unable to read from url '\(url)', " +
                        "got error: \(error.localizedDescription)")
        }
    }

    func getURL() -> URL { url }
}
