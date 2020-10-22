//
//  FileOpener.swift
//  CavernSeer
//
//  Created by Samuel Grush on 7/26/20.
//  Copyright © 2020 Samuel K. Grush. All rights reserved.
//

import Foundation

enum OpenType {
    case scan
    case project
}

final class FileOpener : ObservableObject {

    private var scanStore: ScanStore
    private var projStore: ProjectStore

    @Published
    var showOpenResults = false
    @Published
    var openSuccesses: [URL:OpenType]?
    /// maps _inbox_ URLs to the failure reason
    @Published
    var openFailures: [URL:String]?

    init(_ scanStore: ScanStore, _ projectStore: ProjectStore) {
        self.scanStore = scanStore
        self.projStore = projectStore
    }

    func openURLs(urls: [URL]) {
        if urls.isEmpty {
            return
        }

        var successes: [URL:OpenType] = [:]
        var failures: [URL:String] = [:]

        var lastType: OpenType?

        for url in urls {

            do {
                var newUrl: URL

                switch url.pathExtension {
                    case ScanFile.fileExtension:
                        let model = try SavedScanModel(url: url)
                        newUrl = try scanStore.importFile(model: model)
                        lastType = OpenType.scan
                    case ProjectFile.fileExtension:
                        let model = try SavedProjectModel(url: url)
                        newUrl = try projStore.importFile(model: model)
                        lastType = OpenType.project
                    default:
                        throw FileOpenError.unknownExtension(
                            ext: url.pathExtension)
                }

                successes[newUrl] = lastType

            } catch FileOpenError.noFileInArchive(_) {
                failures[url] = "No file in archive"
            } catch FileOpenError.unknownExtension(let ext) {
                failures[url] = "Unexpected extension '\(ext)'"
            } catch FileSaveError.AlreadyExists {
                failures[url] = "Already exists in store"
            } catch {
                failures[url] = error.localizedDescription
            }
        }

        // TODO
//        if successes.count == 1 && failures.count == 0 {
//            let url = successes.first!
//            switch lastType {
//                case .scan:
//                    break
//                case .project:
//                    break
//                case .none:
//                    break
//            }
//        }

        self.showOpenResults = true
        self.openSuccesses = successes
        self.openFailures = failures
    }
}
