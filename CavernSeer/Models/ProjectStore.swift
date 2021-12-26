//
//  ProjectStore.swift
//  CavernSeer
//
//  Created by Samuel Grush on 7/22/20.
//  Copyright © 2020 Samuel K. Grush. All rights reserved.
//

import Foundation

final class ProjectStore : StoreProtocol {
    typealias FileType = ProjectFile
    typealias ModelType = SavedProjectModel
    typealias CacheType = ProjectCacheFile

    let directoryName: String = "projects"
    let filePrefix: String = FileType.filePrefix
    let fileExtension: String = FileType.fileExtension
    var dataDirectory: URL!
    var cacheDirectory: URL!

    var modelDataInMemory: [SavedProjectModel] = []

    @Published
    var caches = [ProjectCacheFile]()

    @Published
    /// selected `ProjectFile.id`s
    var selection = Set<String>()

    var cacheComparator: CacheComparator {
        CacheSortComparator<ProjectCacheFile>(.fileName)
    }

    internal var fileManager = FileManager.default
    internal var dateFormatter = ISO8601DateFormatter()

    init() {
        (self.dataDirectory, self.cacheDirectory) = self.getOrCreateDirectories()
    }

    func makeErrorCacheInstance(_ url: URL, error: Error) -> ProjectCacheFile {
        return ProjectCacheFile(
            realFileURL: url,
            timestamp: Date(),
            displayName: "Error: \(error.localizedDescription)",
            img: nil
        )
    }
}
