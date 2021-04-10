//
//  StoreProtocol.swift
//  CavernSeer
//
//  Created by Samuel Grush on 7/22/20.
//  Copyright © 2020 Samuel K. Grush. All rights reserved.
//

import Foundation

protocol StoreProtocol : ObservableObject {
    associatedtype ModelType: SavedStoredFileProtocol
    associatedtype FileType: StoredFileProtocol = ModelType.FileType
    associatedtype PreviewType: PreviewStoredFileProtocol
        = ModelType.PreviewType

    var directoryName: String { get }
    var filePrefix: String { get }
    var fileExtension: String { get }
    var directory: URL! { get }

    var fileManager: FileManager { get }
    var dateFormatter: ISO8601DateFormatter { get }

    var cachedModelData: [ModelType] { get set }

    var previews: [PreviewType] { get set }
}


extension StoreProtocol {

    static var MaxCachedModels: Int { 2 }

    /**
     * Try to get a model from a baseName; first try the cache, then try the file
     *  otherwise throws from the `ModelType` constructor.
     */
    func getModel(url: URL) throws -> ModelType {
        if let model = cachedModelData.first(where: { $0.url == url }) {
            return model
        }

        let model = try ModelType(url: url)

        let cacheToRemove = cachedModelData.count - Self.MaxCachedModels + 1
        if cacheToRemove > 0 {
            cachedModelData.removeFirst(cacheToRemove)
        }
        cachedModelData.append(model)

        return model
    }

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

    /**
     * Update the `previews` and `cachedModelData` based on the files in `directory`.
     */
    func update() throws {
        let newURLs = getDirectoryURLs()

        let alreadyPreviewedURLs = previews.map { preview in preview.url }
        let alreadyCachedURLs = cachedModelData.map { model in model.url }

        let indicesToRemove = IndexSet(
            alreadyCachedURLs.indices.filter {
                (index: Int) -> Bool in
                let url = alreadyCachedURLs[index]
                return  !newURLs.contains(url)
            }
        )
        cachedModelData.remove(atOffsets: indicesToRemove)

        // add or remove previews
        for change in newURLs.difference(from: alreadyPreviewedURLs) {
            switch change {
                case let .remove(offset, _, _):
                    previews.remove(at: offset)
                case let .insert(offset, url, _):
                    let newDatum = try PreviewType(url: url)
                    previews.insert(newDatum, at: offset)
            }
        }
    }

    func deleteFile(id: String) {
        let previewIndex = previews.firstIndex { $0.id == id }
        let modelIndex = cachedModelData.firstIndex { $0.id == id }

        if previewIndex != nil {
            let url = previews[previewIndex!].url
            do {
                try fileManager.removeItem(at: url)
            } catch {
                fatalError("Deletion failed: \(error.localizedDescription)")
            }
            previews.remove(at: previewIndex!)
        } else {
            fatalError("Model not found in modelData")
        }

        if modelIndex != nil {
            cachedModelData.remove(at: modelIndex!)
        }
    }

    func importFile(model: ModelType) throws -> URL {
        if previews.contains(where: { $0.id == model.id }) {
            throw FileSaveError.AlreadyExists
        }

        let file = model.getFile() as! Self.FileType
        return try saveFile(file: file, baseName: model.id)
    }

    internal func getSaveURL(file: FileType, baseName: String? = nil) -> URL {
        let base = baseName ?? file.name

        return baseNameToURL(base: base)
    }

    internal func baseNameToURL(base: String) -> URL {
        return directory
            .appendingPathComponent(base)
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
