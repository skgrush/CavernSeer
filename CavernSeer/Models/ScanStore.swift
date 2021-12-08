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

    /**
     * Try to set the visible scan in the list.
     *
     * - Parameters:
     *   - visible: the URL of the scan to set as the visible option.
     *   - updateFirst: if we should update the store before setting visible, e.g. if `visible` is
     *      not currently loaded.
     *   - onError: only necessary if `updateFirst` is true. Callback in case `update` fails.
     */
    func setVisible(
        visible: URL,
        updateFirst: Bool = false,
        onError: ((Error)->())? = nil
    ) {
        let nextVisibleScanId =
            visible.deletingPathExtension().lastPathComponent

        /// try clearing the current selection and wait for the view to handle that
        self.visibleScan = nil
        DispatchQueue.main.async {
            /// if we're updating, wait for the callback, otherwise just set the `visibleScan`
            if updateFirst {
                self.update() {
                    err in
                    if err == nil {
                        /// if the update was successful, again asynchronously set the `visibleScan`
                        DispatchQueue.main.async {
                            self.visibleScan = nextVisibleScanId
                        }
                    } else {
                        onError?(err!)
                    }
                }
            } else {
                self.visibleScan = nextVisibleScanId
            }
        }
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

    func copySaveFile(scanFile: ScanFile, name: String, withLocation: Bool) throws -> URL {
        let newScan = ScanFile(
            name: name,
            timestamp: scanFile.timestamp,
            center: scanFile.center,
            extent: scanFile.extent,
            meshAnchors: scanFile.meshAnchors,
            startSnapshot: scanFile.startSnapshot,
            endSnapshot: scanFile.endSnapshot,
            stations: scanFile.stations,
            lines: scanFile.lines,
            location: withLocation ? scanFile.location : nil
        )

        let newUrl = try self.saveFile(file: newScan)

        return newUrl
    }

    func makeErrorCacheInstance(_ url: URL, error: Error) -> ScanCacheFile {
        return ScanCacheFile(
            realFileURL: url,
            timestamp: Date.distantFuture,
            displayName: "Error! \(url.deletingPathExtension().lastPathComponent)",
            img: nil,
            error: error
        )
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
