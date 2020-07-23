//
//  StoreProtocol.swift
//  CavernSeer
//
//  Created by Samuel Grush on 7/22/20.
//  Copyright © 2020 Samuel K. Grush. All rights reserved.
//

import Foundation

protocol StoredFileProtocol : NSObject, NSSecureCoding {
    func getTimestamp() -> Date
}

protocol SavedStoredFileProtocol {
    init(url: URL)
    func getURL() -> URL
}

protocol StoreProtocol : ObservableObject {
    associatedtype FileType: StoredFileProtocol
    associatedtype ModelType: SavedStoredFileProtocol

    var directoryName: String { get }
    var filePrefix: String { get }
    var fileExtension: String { get }
    var directory: URL! { get }

    var fileManager: FileManager { get }
    var dateFormatter: ISO8601DateFormatter { get }

    var modelData: [ModelType] { get set }
}


extension StoreProtocol {

    func saveFile(file: FileType) throws {
        let newSaveUrl = getSaveURL(file: file)

        let data = try NSKeyedArchiver.archivedData(
            withRootObject: file,
            requiringSecureCoding: true
        )
        try data.write(to: newSaveUrl, options: [.atomic])
    }

    func update(urls: [URL]? = nil) {
        let newURLs = urls ?? getDirectoryURLs()

        let cachedURLs = modelData.map { model in model.getURL() }

        let difference = newURLs.difference(from: cachedURLs)

        for change in difference {
            switch change {
                case let .remove(offset, _, _):
                    modelData.remove(at: offset)
                case let .insert(offset, url, _):
                    let newDatum = ModelType(url: url)
                    modelData.insert(newDatum, at: offset)
            }
        }
    }

    func deleteFile(model: ModelType) {
        let modelURL = model.getURL()
        let index = modelData.firstIndex(where: { $0.getURL() == modelURL })
        if index != nil {
            do {
                try fileManager.removeItem(at: modelURL)
            } catch {
                fatalError("Deletion failed: \(error.localizedDescription)")
            }
            modelData.remove(at: index!)
        } else {
            fatalError("Model not found in modelData")
        }
    }

    internal func getSaveURL(file: FileType) -> URL {
        dateFormatter.timeZone = TimeZone.current
        let dateString = dateFormatter.string(from: file.getTimestamp())

        return directory
            .appendingPathComponent("\(filePrefix)_\(dateString)")
            .appendingPathExtension(fileExtension)
    }

    internal func getOrCreateDirectory() -> URL {
        do {
            let directory = try
                fileManager
                    .url(for: .documentDirectory,
                         in: .userDomainMask,
                         appropriateFor: nil,
                         create: true)
                .appendingPathComponent(directoryName, isDirectory: true)

            if (!(try directory.checkResourceIsReachable())) {
                try fileManager
                    .createDirectory(at: directory,
                                     withIntermediateDirectories: false)
            }

            return directory
        } catch {
            fatalError("Could not resolve file directory URL; " +
                       "\(error.localizedDescription)")
        }
    }

    internal func getDirectoryURLs() -> [URL] {
        do {
            let contents = try fileManager
                .contentsOfDirectory(
                    at: directory,
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
}
