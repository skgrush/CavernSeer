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

    var directoryName: String { "scans" }
    var filePrefix: String { "scan" }
    var fileExtension: String { FileType.fileExtension }
    var directory: URL!

    @Published
    var modelData: [SavedScanModel]

    @Published
    var selection = Set<String>()

    internal var fileManager = FileManager.default
    internal var dateFormatter = ISO8601DateFormatter()

    init(data: [SavedScanModel] = []) {
        modelData = data

        directory = getOrCreateDirectory()
    }
}


#if DEBUG

let dummyData: [SavedScanModel] = [
    SavedScanModel(id: "hat.arscanfile"),
    SavedScanModel(id: "bat.arscanfile"),
    SavedScanModel(id: "tat.arscanfile"),
]

#endif
