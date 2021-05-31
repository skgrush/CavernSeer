//
//  ScanStore.swift
//  CavernSeer
//
//  Created by Samuel Grush on 6/27/20.
//  Copyright © 2020 Samuel K. Grush. All rights reserved.
//

import Foundation

final class ScanStore : StoreProtocol {
    typealias FileType = ScanFile
    typealias ModelType = SavedScanModel
    typealias CacheType = ScanCacheFile

    let directoryName: String = "scans"
    let filePrefix: String = FileType.filePrefix
    let fileExtension: String = FileType.fileExtension
    var dataDirectory: URL!
    var cacheDirectory: URL!

    var modelDataInMemory: [SavedScanModel] = []

    @Published
    var caches = [ScanCacheFile]()

    @Published
    var selection = Set<String>()

    @Published
    var visibleScan: String?

    internal var fileManager = FileManager.default
    internal var dateFormatter = ISO8601DateFormatter()

    init() {
        (self.dataDirectory, self.cacheDirectory) = getOrCreateDirectories()
    }

    func setVisible(visible: URL) {
        self.visibleScan = visible.lastPathComponent
    }

    func getSelectionModels() -> [SavedScanModel] {
        do {
            return try self.selection
                .compactMap {
                    id in
                    self.caches.first { $0.id == id }?.realFileURL
                }
                .map {
                    try self.getModel(url: $0)
                }
        } catch {
            fatalError(
                "Failed to get selected models: \(error.localizedDescription)"
            )
        }
    }
}


#if DEBUG

let dummySavedScans: [SavedScanModel] = [
    .init(id: "hat"),
    .init(id: "bat"),
    .init(id: "tat"),
]

let dummyScanCaches: [ScanCacheFile] = [
    .init(id: "hat"),
    .init(id: "bat"),
    .init(id: "tat"),
]

#endif
