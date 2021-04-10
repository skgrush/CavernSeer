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
    typealias PreviewType = PreviewScanModel

    let directoryName: String = "scans"
    let filePrefix: String = FileType.filePrefix
    let fileExtension: String = FileType.fileExtension
    var directory: URL!

    var cachedModelData: [SavedScanModel] = []

    @Published
    var previews: [PreviewType] = []

    @Published
    var selection = Set<String>()

    @Published
    var visibleScan: String?

    internal var fileManager = FileManager.default
    internal var dateFormatter = ISO8601DateFormatter()

    init() {
        directory = getOrCreateDirectory()
    }

    func setVisible(visible: URL) {
        self.visibleScan = visible.lastPathComponent
    }

    func getSelectionModels() -> [SavedScanModel] {
        do {
            return try self.selection
                .compactMap {
                    id in
                    self.previews.first { $0.id == id }?.url
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
    .init(id: "hat.cavernseerscan"),
    .init(id: "bat.cavernseerscan"),
    .init(id: "tat.cavernseerscan"),
]

let dummyPreviewScans: [PreviewScanModel] = [
    .init(id: "hat.cavernseerscan"),
    .init(id: "bat.cavernseerscan"),
    .init(id: "tat.cavernseerscan"),
]

#endif
