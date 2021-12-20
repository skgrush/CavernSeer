//
//  simd+simd.swift
//  CavernSeer
//
//  Created by Samuel Grush on 12/19/21.
//  Copyright © 2021 Samuel K. Grush. All rights reserved.
//

import Foundation
import ARKit

extension simd_float4x4 {
    func toPosition() -> simd_float3 {
        let col = self.columns.3
        return .init(
            col.x,
            col.y,
            col.z
        )
    }
}
