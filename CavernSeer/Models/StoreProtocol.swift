//
//  StoreProtocol.swift
//  CavernSeer
//
//  Created by Samuel Grush on 7/22/20.
//  Copyright © 2020 Samuel K. Grush. All rights reserved.
//

import Foundation

protocol StoredFileProtocol : NSObject, NSSecureCoding {
    static var fileExtension: String { get }
    func getTimestamp() -> Date
}

protocol SavedStoredFileProtocol {
    associatedtype FileType: StoredFileProtocol

    var id: String { get }
    init(url: URL) throws
    func getURL() -> URL
    func getFile() -> FileType
}

protocol StoreProtocol : ObservableObject {
    associatedtype ModelType: SavedStoredFileProtocol
    // associatedtype FileType: StoredFileProtocol
    associatedtype FileType: StoredFileProtocol = ModelType.FileType

    var directoryName: String { get }
    var filePrefix: String { get }
    var fileExtension: String { get }
    var directory: URL! { get }

    var fileManager: FileManager { get }
    var dateFormatter: ISO8601DateFormatter { get }

    var modelData: [ModelType] { get set }
}


extension StoreProtocol {

    /**
     * Save a file to the store directory.
     *
     * - Parameter file: the `FileType` instance being saved
     * - Parameter baseName: an optional base name to use for the saved file. Otherwise `url.lastPathComponent`.
     */
    func saveFile(file: FileType, baseName: String? = nil) throws -> URL {
        let newSaveUrl = getSaveURL(file: file, baseName: baseName)

        let data = try NSKeyedArchiver.archivedData(
            withRootObject: file,
            requiringSecureCoding: true
        )
        try data.write(to: newSaveUrl, options: [.atomic])

        return newSaveUrl
    }

    func update(urls: [URL]? = nil) throws {
        let newURLs = urls ?? getDirectoryURLs()

        let cachedURLs = modelData.map { model in model.getURL() }

        let difference = newURLs.difference(from: cachedURLs)

        for change in difference {
            switch change {
                case let .remove(offset, _, _):
                    modelData.remove(at: offset)
                case let .insert(offset, url, _):
                    let newDatum = try ModelType(url: url)
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

    func importFile(model: ModelType) throws -> URL {
        if modelData.contains(where: { $0.id == model.id }) {
            throw FileSaveError.AlreadyExists
        }

        let file = model.getFile() as! Self.FileType
        return try saveFile(file: file, baseName: model.id)
    }

    internal func getSaveURL(file: FileType, baseName: String? = nil) -> URL {
        var base: String? = baseName
        if base == nil {
            dateFormatter.timeZone = TimeZone.current
            let dateString = dateFormatter.string(from: file.getTimestamp())
            base = "\(filePrefix)_\(dateString)"
        }

        return directory
            .appendingPathComponent(base!)
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

            //if (!(try directory.checkResourceIsReachable())) {
            try fileManager
                .createDirectory(at: directory,
                                 withIntermediateDirectories: true)
            //}

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
