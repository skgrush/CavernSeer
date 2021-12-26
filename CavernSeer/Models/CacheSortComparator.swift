//
//  CacheSortComparator.swift
//  CavernSeer
//
//  Created by Samuel Grush on 12/22/21.
//  Copyright © 2021 Samuel K. Grush. All rights reserved.
//

import Foundation

class CacheSortComparator<TCache : StoredCacheFileProtocol> : SortComparator {
    typealias Compared = TCache

    private let compareMethod: (Compared, Compared) -> ComparisonResult
    let method: SortMethod
    var order: SortOrder

    init(_ method: SortMethod, _ order: SortOrder = .forward) {
        self.method = method
        self.order = order
        self.compareMethod = Self.getMethod(method)
    }

    func compare(_ lhs: Compared, _ rhs: Compared) -> ComparisonResult {
        let result = compareMethod(lhs, rhs)
        if order == .reverse {
            return result.reverse()
        }
        return result
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(method)
        hasher.combine(order)
    }

    static func == (lhs: CacheSortComparator, rhs: CacheSortComparator) -> Bool {
        lhs.method == rhs.method && lhs.order == rhs.order
    }

    private static func getMethod(
        _ method: SortMethod
    ) -> ((Compared, Compared) -> ComparisonResult) {

        switch method {
            case .scanDate:
                return { $0.timestamp.compare($1.timestamp) }
            case .fileName:
                return { $0.id.compare($1.id) }
            case .name:
                return { $0.displayName.compare($1.id) }
        }
    }
}
