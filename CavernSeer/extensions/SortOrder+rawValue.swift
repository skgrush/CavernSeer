//
//  SortOrder+rawValue.swift
//  CavernSeer
//
//  Created by Samuel Grush on 12/25/21.
//  Copyright © 2021 Samuel K. Grush. All rights reserved.
//

import Foundation

extension SortOrder {

    var rawValue: Int {
        switch self {
            case .forward:
                return 1
            case .reverse:
                return 2
        }
    }

    init?(rawValue: Int) {
        switch rawValue {
            case 1:
                self = .forward
            case 2:
                self = .reverse
            default:
                return nil
        }
    }
}
