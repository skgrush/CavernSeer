//
//  PreviewStoredFileProtocol.swift
//  CavernSeer
//
//  Created by Samuel Grush on 12/30/20.
//  Copyright © 2020 Samuel K. Grush. All rights reserved.
//

import Foundation

/**
 * A minimal representation of a `SavedStoredFileProtocol` implementation.
 */
protocol PreviewStoredFileProtocol {
    var id: String { get }
    var url: URL { get }
    var imageData: Data? { get }
    init(url: URL) throws
}
