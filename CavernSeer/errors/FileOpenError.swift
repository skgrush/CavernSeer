//
//  FileOpenError.swift
//  CavernSeer
//
//  Created by Samuel Grush on 7/26/20.
//  Copyright © 2020 Samuel K. Grush. All rights reserved.
//

import Foundation

enum FileOpenError : Error {
    case noFileInArchive(url: URL)
    case unknownExtension(ext: String)
    case decodeError(err: String)
}

extension FileOpenError : LocalizedError {
    var errorDescription: String? {
        switch self {
            case FileOpenError.noFileInArchive(_):
                return "No file in archive"
            case FileOpenError.unknownExtension(let ext):
                return "Unexpected extension '\(ext)'"
            case FileOpenError.decodeError(let err):
                return "Decoding error: \(err)"
            default:
                return nil
        }
    }
}
