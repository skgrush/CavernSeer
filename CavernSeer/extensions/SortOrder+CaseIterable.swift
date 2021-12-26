//
//  SortOrder+CaseIterable.swift
//  CavernSeer
//
//  Created by Samuel Grush on 12/25/21.
//  Copyright © 2021 Samuel K. Grush. All rights reserved.
//

import Foundation

extension SortOrder : CaseIterable {
    public static var allCases: [SortOrder] = [.forward, .reverse]
}
