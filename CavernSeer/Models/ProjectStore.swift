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
    typealias PreviewType = PreviewProjectModel

    let directoryName: String = "projects"
    let filePrefix: String = FileType.filePrefix
    let fileExtension: String = FileType.fileExtension
    var directory: URL!

    var cachedModelData: [ModelType] = []

    @Published
    var previews: [PreviewType] = []

    @Published
    /// selected `ProjectFile.id`s
    var selection = Set<String>()

    internal var fileManager = FileManager.default
    internal var dateFormatter = ISO8601DateFormatter()

    init() {
        directory = getOrCreateDirectory()
    }
}
