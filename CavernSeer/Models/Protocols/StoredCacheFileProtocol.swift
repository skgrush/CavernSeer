//
//  StoredCacheFileProtocol.swift
//  CavernSeer
//
//  Created by Samuel Grush on 5/29/21.
//  Copyright © 2021 Samuel K. Grush. All rights reserved.
//

import Foundation

protocol StoredCacheFileProtocol : Identifiable, NSObject, NSSecureCoding {
    static var filePrefix: String { get }
    static var fileExtension: String { get }

    /** base filename with no extension */
    var id: String { get }
    var timestamp: Date { get }
    var displayName: String { get }
    var realFileURL: URL? { get set }

    var jpegImageData: Data? { get }
}

extension StoredCacheFileProtocol {
    func getCacheURL(cacheDir: URL) -> URL {
        return cacheDir
            .appendingPathComponent(self.id)
            .appendingPathExtension(Self.fileExtension)
    }
}
