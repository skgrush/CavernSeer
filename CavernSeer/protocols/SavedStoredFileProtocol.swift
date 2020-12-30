//
//  SavedStoredFileProtocol.swift
//  CavernSeer
//
//  Created by Samuel Grush on 12/30/20.
//  Copyright © 2020 Samuel K. Grush. All rights reserved.
//

import Foundation

protocol SavedStoredFileProtocol {
    associatedtype FileType: StoredFileProtocol

    var id: String { get }
    init(url: URL) throws
    func getURL() -> URL
    func getFile() -> FileType
}
