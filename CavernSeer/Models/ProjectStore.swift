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

    var directoryName: String { "projects" }
    var filePrefix: String { "proj" }
    var fileExtension: String { FileType.fileExtension }
    var directory: URL!

    @Published
    var modelData: [SavedProjectModel] = []

    @Published
    /// selected `ProjectFile.id`s
    var selection = Set<String>()

    internal var fileManager = FileManager.default
    internal var dateFormatter = ISO8601DateFormatter()

    init() {
        directory = getOrCreateDirectory()
    }
}
