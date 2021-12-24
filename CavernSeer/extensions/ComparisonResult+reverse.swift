//
//  ComparisonResult+reverse.swift
//  CavernSeer
//
//  Created by Samuel Grush on 12/23/21.
//  Copyright © 2021 Samuel K. Grush. All rights reserved.
//

import Foundation

@available(iOS 15, *)
extension ComparisonResult {
    func reverse() -> ComparisonResult {
        .init(rawValue: -self.rawValue)!
    }
}
