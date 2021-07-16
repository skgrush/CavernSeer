//
//  FileSaveError.swift
//  CavernSeer
//
//  Created by Samuel Grush on 7/26/20.
//  Copyright © 2020 Samuel K. Grush. All rights reserved.
//

import Foundation

enum FileSaveError : Error {
    case AlreadyExists
}

extension FileSaveError : LocalizedError {
    var errorDescription: String? {
        switch self {
            case .AlreadyExists:
                return "Already exists in store"
            default:
                return nil
        }
    }
}
