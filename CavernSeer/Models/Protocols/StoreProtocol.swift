//
//  StoreProtocol.swift
//  CavernSeer
//
//  Created by Samuel Grush on 7/22/20.
//  Copyright © 2020 Samuel K. Grush. All rights reserved.
//

import Foundation

/**
 * Abstracts the storage and handling of files and their caches.
 *
 * The definitive file list is defined by the `dataDirectory`, but the cache files in the `cacheDirectory`
 * are the ones kept in memory.
 */
protocol StoreProtocol : ObservableObject {
    associatedtype ModelType: SavedStoredFileProtocol

    typealias FileType = ModelType.FileType
    typealias CacheType = FileType.CacheType
    typealias CacheComparator = CacheSortComparator<CacheType>

    /** basename of directories used for stored files and previews */
    var directoryName: String { get }
    var filePrefix: String { get }
    var fileExtension: String { get }
    var dataDirectory: URL! { get }
    var cacheDirectory: URL! { get }

    var fileManager: FileManager { get }
    var dateFormatter: ISO8601DateFormatter { get }

    var modelDataInMemory: [ModelType] { get set }

    var caches: [CacheType] { get set }

    var cacheComparator: CacheComparator { get }

    func makeErrorCacheInstance(_ url: URL, error: Error) -> CacheType
}


extension StoreProtocol {

    static var MaxInMemoryModels: Int { 2 }

    func sortCaches(_ comparator: CacheComparator? = nil) {
        let cmp = comparator ?? self.cacheComparator
        self.caches.sort(using: cmp)
    }

    /**
     * Try to get a model from a baseName; first try the cache, then try the file
     *  otherwise throws from the `ModelType` constructor.
     */
    func getModel(url: URL) throws -> ModelType {
        if let model = modelDataInMemory.first(where: { $0.url == url }) {
            return model
        }

        let model = try ModelType(url: url)

        let cacheToRemove = modelDataInMemory.count - Self.MaxInMemoryModels + 1
        if cacheToRemove > 0 {
            modelDataInMemory.removeFirst(cacheToRemove)
        }
        modelDataInMemory.append(model)

        return model
    }

    /**
     * Save a file to the store directory.
     *
     * - Parameter file: the `FileType` instance being saved
     * - Parameter baseName: an optional base name to use for the saved file. Otherwise `url.lastPathComponent`.
     */
    func saveFile(file: FileType, baseName: String? = nil) throws -> URL {
        let cache = file.createCacheFile(thisFileURL: self.dataDirectory)

        let newSaveUrl = getSaveURL(file: file, baseName: baseName)
        let dataData = try NSKeyedArchiver.archivedData(
            withRootObject: file,
            requiringSecureCoding: true
        )
        try dataData.write(to: newSaveUrl, options: [.atomic])

        let cacheUrl = cache.getCacheURL(cacheDir: cacheDirectory)
        let cacheData = try NSKeyedArchiver.archivedData(
            withRootObject: cache,
            requiringSecureCoding: true
        )
        try cacheData.write(to: cacheUrl)

        return newSaveUrl
    }

    /**
     * Update the `caches` and `modelDataInMemory` based on the files in `dataDirectory`.
     *
     * Work is done async as utility, then data is updated back on main thread.
     * If `completion` is provided, it is called in that main thread.
     */
    func update(completion: ((Error?)->())? = nil) {
        var newCaches = caches
        DispatchQueue.global(qos: .utility).async {
            let newURLs = self.getStoreDirectoryURLs()

            let alreadyLoadedCacheURLs = self.caches.map {
                cache -> URL in self.getNormalizedRealUrl(cache: cache)
            }
            let alreadyInMemoryURLs = self.modelDataInMemory.map {
                model in model.url
            }

            let indicesToRemove = IndexSet(
                alreadyInMemoryURLs.indices.filter {
                    (index: Int) -> Bool in
                    let url = alreadyLoadedCacheURLs[index]
                    return  !newURLs.contains(url)
                }
            )

            // add or remove caches based on new URLs
            for change in newURLs.difference(from: alreadyLoadedCacheURLs) {
                switch change {
                    case let .remove(offset, _, _):
                        newCaches.remove(at: offset)
                    case let .insert(offset, url, _):
                        do {
                            let newDatum = try self.getCacheFile(
                                realFileURL: url
                            )
                            newCaches.insert(newDatum, at: offset)
                        } catch {
                            let errCache = self.makeErrorCacheInstance(url, error: error)
                            newCaches.insert(errCache, at: offset)
                        }
                }
            }

            DispatchQueue.main.async {
                self.modelDataInMemory.remove(atOffsets: indicesToRemove)

                self.caches.removeAll()
                self.caches.append(contentsOf: newCaches)
                self.sortCaches()

                completion?(nil)
            }
        }
    }

    func deleteFile(id: String) {
        let cacheIndex = caches.firstIndex { $0.id == id }
        let modelIndex = modelDataInMemory.firstIndex { $0.id == id }

        if cacheIndex != nil {
            let cache = caches[cacheIndex!]
            let dataUrl = self.getNormalizedRealUrl(cache: cache)
            let cacheUrl = cache.getCacheURL(cacheDir: cacheDirectory)
            do {
                try fileManager.removeItem(at: cacheUrl)
            } catch {
                debugPrint("Deleting cacheUrl failed but that's okay", cacheUrl)
            }
            do {
                try fileManager.removeItem(at: dataUrl)
            } catch {
                fatalError("Deletion failed: \(error.localizedDescription)")
            }
            caches.remove(at: cacheIndex!)
        } else {
            fatalError("Model not found in modelData")
        }

        if modelIndex != nil {
            modelDataInMemory.remove(at: modelIndex!)
        }
    }

    func importFile(model: ModelType) throws -> URL {
        if caches.contains(where: { $0.id == model.id }) {
            throw FileSaveError.AlreadyExists
        }

        let file = model.getFile()
        return try saveFile(file: file, baseName: model.id)
    }

    func clearCaches() throws {
        try fileManager.removeItem(at: cacheDirectory)
        caches.removeAll()
        modelDataInMemory.removeAll()
        _ = getOrCreateDirectories()
    }

    internal func DANGEROUSLY_deleteAllFiles() throws {
        try fileManager.removeItem(at: dataDirectory)
        try clearCaches()
    }

    internal func getSaveURL(file: FileType, baseName: String? = nil) -> URL {
        let base = baseName ?? file.name

        return baseNameToURL(base: base)
    }

    internal func baseNameToURL(base: String) -> URL {
        return dataDirectory
            .appendingPathComponent(base)
            .appendingPathExtension(fileExtension)
    }

    internal func getNormalizedRealUrl(cache: CacheType) -> URL {
        if cache.realFileURL == nil {
            cache.realFileURL
                = dataDirectory
                    .appendingPathComponent(cache.id)
                    .appendingPathExtension(fileExtension)
        }
        return cache.realFileURL!
    }

    /**
     * Tries to get the cache file associated with a real file.
     * If the cache file doesn't exist but the real file does, generate the cache file and save it too.
     */
    internal func getCacheFile(realFileURL: URL) throws -> CacheType {
        let id = realFileURL.deletingPathExtension().lastPathComponent

        let cacheFileURL =
            cacheDirectory
                .appendingPathComponent(id)
                .appendingPathExtension(CacheType.fileExtension)

        if fileManager.fileExists(atPath: cacheFileURL.path) {
            // if the cache file exists just get it
            let data = try Data(contentsOf: cacheFileURL)
            return try NSKeyedUnarchiver.unarchivedObject(
                ofClass: CacheType.self,
                from: data
            )!
        } else if fileManager.fileExists(atPath: realFileURL.path) {
            debugPrint(
                "Cache file doesn't exist but real file does",
                realFileURL
            )
            // if we haven't cached the file yet, read it then write the cache
            let model = try ModelType(url: realFileURL)
            let modelFile = model.getFile()
            let cacheFile = modelFile.createCacheFile(
                thisFileURL: realFileURL
            )
            let cacheFileData = try NSKeyedArchiver.archivedData(
                withRootObject: cacheFile,
                requiringSecureCoding: true
            )
            try cacheFileData.write(to: cacheFileURL, options: [.atomic])
            _ = self.getNormalizedRealUrl(cache: cacheFile)
            return cacheFile
        } else {
            throw FileOpenError.noFileInArchive(url: realFileURL)
        }
    }

    /**
     * Create the file and cache directories, and return them as a tuple.
     * Returns `(fileDirectory, cacheDirectory)`
     */
    internal func getOrCreateDirectories() -> (URL, URL) {
        do {
            let fileDirectory = try
                fileManager
                    .url(for: .documentDirectory,
                         in: .userDomainMask,
                         appropriateFor: nil,
                         create: true)
                .appendingPathComponent(directoryName, isDirectory: true)
            let cacheDirectory = try
                fileManager
                .url(for: .cachesDirectory,
                     in: .userDomainMask,
                     appropriateFor: nil,
                     create: true)
                .appendingPathComponent(directoryName, isDirectory: true)

            try fileManager
                .createDirectory(at: fileDirectory,
                                 withIntermediateDirectories: true)
            try fileManager
                .createDirectory(at: cacheDirectory,
                                 withIntermediateDirectories: true)

            return (fileDirectory, cacheDirectory)
        } catch {
            fatalError("Could not resolve file dataDirectory URL; " +
                       "\(error.localizedDescription)")
        }
    }

    internal func getStoreDirectoryURLs() -> [URL] {
        do {
            let contents = try fileManager
                .contentsOfDirectory(
                    at: dataDirectory,
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
            fatalError("Could not resolve dataDirectory contents")
        }
    }
}
