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
}
