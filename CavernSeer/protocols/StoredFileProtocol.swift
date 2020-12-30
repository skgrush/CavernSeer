//
//  StoredFileProtocol.swift
//  CavernSeer
//
//  Created by Samuel Grush on 12/30/20.
//  Copyright © 2020 Samuel K. Grush. All rights reserved.
//

import Foundation

protocol StoredFileProtocol : NSObject, NSSecureCoding {
    static var fileExtension: String { get }
    func getTimestamp() -> Date
}
