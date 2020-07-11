//
//  ScanStore.swift
//  CavernSeer
//
//  Created by Samuel Grush on 6/27/20.
//  Copyright © 2020 Samuel K. Grush. All rights reserved.
//

import Foundation

class ScanStore : ObservableObject {
    let fileExtension = "arscanfile"

    @Published
    var modelData: [SavedScanModel]

    var scanDirectory: URL

    private let fileManager = FileManager.default
    private let dateFormatter = ISO8601DateFormatter()

    init(data: [SavedScanModel] = []) {
        modelData = data

        do {
            self.scanDirectory = try
                fileManager
                    .url(for: .documentDirectory,
                         in: .userDomainMask,
                         appropriateFor: nil,
                         create: true)
        } catch {
            fatalError("Could not resolve scanDirectory URL; " +
                       "\(error.localizedDescription)")
        }
    }

    func update(urls: [URL]? = nil) {
        let newURLs = urls ?? getDirectoryURLs()

        let cachedURLs = modelData.map { scan in scan.url }

        let difference = newURLs.difference(from: cachedURLs)

        for change in difference {
            switch change {
                case let .remove(offset, _, _):
                    modelData.remove(at: offset)
                case let .insert(offset, url, _):
                    let newDatum = SavedScanModel(url: url)
                    modelData.insert(newDatum, at: offset)
            }
        }
    }

    func saveScanFile(scanFile: ScanFile) throws {
        let newSaveURL = getSaveURL(scanFile: scanFile)

        let data = try NSKeyedArchiver.archivedData(
            withRootObject: scanFile,
            requiringSecureCoding: true)
        try data.write(to: newSaveURL, options: [.atomic])
    }

    func deleteFile(model: SavedScanModel) {
        let index = modelData.firstIndex(where: { $0.url == model.url })
        if index != nil {
            do {
                try fileManager.removeItem(at: model.url)
            } catch {
                fatalError("Deletion failed: \(error.localizedDescription)")
            }
            modelData.remove(at: index!)
        } else {
            fatalError("Model not found in modelData")
        }
    }

    private func getDirectoryURLs() -> [URL] {
        do {
            let contents = try FileManager.default
                .contentsOfDirectory(
                    at: scanDirectory,
                    includingPropertiesForKeys: nil
                )

            return contents
                .filter { url in url.pathExtension == fileExtension }
                .sorted(by: { (url1, url2) -> Bool in
                    url1
                        .absoluteString
                        .lexicographicallyPrecedes(url2.absoluteString)
                })
        } catch {
            fatalError("Could not resolve directory contents")
        }
    }

    private func getSaveURL(scanFile: ScanFile) -> URL {
        dateFormatter.timeZone = TimeZone.current
        let dateString = dateFormatter.string(from: scanFile.timestamp)

        return scanDirectory
            .appendingPathComponent("scan_\(dateString)")
            .appendingPathExtension(fileExtension)
    }
}


#if DEBUG

let dummyData: [SavedScanModel] = [
    SavedScanModel(id: "hat.arscanfile"),
    SavedScanModel(id: "bat.arscanfile"),
    SavedScanModel(id: "tat.arscanfile"),
]

#endif
