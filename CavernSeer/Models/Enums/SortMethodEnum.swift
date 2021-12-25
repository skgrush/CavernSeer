//
//  SortMethodEnum.swift
//  CavernSeer
//
//  Created by Samuel Grush on 12/22/21.
//  Copyright © 2021 Samuel K. Grush. All rights reserved.
//

import Foundation

enum SortMethod: Int, CaseIterable, Identifiable, Equatable {
    case fileName = 1
    case scanDate
    case name

    var id: Int { rawValue }
}

extension SortMethod {
    var name: String {
        switch self {
            case .fileName:
                return "File name"
            case .scanDate:
                return "Scan date"
            case .name:
                return "Name"
        }
    }
}
