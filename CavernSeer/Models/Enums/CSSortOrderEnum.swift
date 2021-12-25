//
//  CSSortOrderEnum.swift
//  CavernSeer
//
//  Created by Samuel Grush on 12/23/21.
//  Copyright © 2021 Samuel K. Grush. All rights reserved.
//

import Foundation

enum CSSortOrder: Int, CaseIterable, Identifiable, Equatable {
    case forward
    case reverse

    var id: Int { rawValue }
}

extension CSSortOrder {
    var name: String {
        switch self {
            case .forward:
                return "Ascending"
            case .reverse:
                return "Descending"
        }
    }

    @available(iOS 15, *)
    func toSortOrder() -> SortOrder {
        switch self {
            case .forward:
                return .forward
            case .reverse:
                return .reverse
        }
    }
}
