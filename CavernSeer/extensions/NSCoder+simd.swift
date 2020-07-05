//
//  NSCoder+simd.swift
//  CavernSeer
//
//  Created by Samuel Grush on 6/29/20.
//  Copyright © 2020 Samuel K. Grush. All rights reserved.
//

import Foundation
import simd

extension NSCoder {

    func decode_simd_float3(prefix: String) -> simd_float3 {
        let x = self.decodeFloat(forKey: "\(prefix)_x")
        let y = self.decodeFloat(forKey: "\(prefix)_y")
        let z = self.decodeFloat(forKey: "\(prefix)_z")

        return simd_make_float3(x, y, z)
    }

    func encode(_ vec: simd_float3, forPrefix: String) {
        self.encode(Float(vec.x), forKey: "\(forPrefix)_x")
        self.encode(Float(vec.y), forKey: "\(forPrefix)_y")
        self.encode(Float(vec.z), forKey: "\(forPrefix)_z")
    }

    func decode_simd_float4(prefix: String) -> simd_float4 {
        let x = self.decodeFloat(forKey: "\(prefix)_x")
        let y = self.decodeFloat(forKey: "\(prefix)_y")
        let z = self.decodeFloat(forKey: "\(prefix)_z")
        let w = self.decodeFloat(forKey: "\(prefix)_w")

        return simd_make_float4(x, y, z, w)
    }

    func encode(_ vec: simd_float4, forPrefix: String) {
        self.encode(Float(vec.x), forKey: "\(forPrefix)_x")
        self.encode(Float(vec.y), forKey: "\(forPrefix)_y")
        self.encode(Float(vec.z), forKey: "\(forPrefix)_z")
        self.encode(Float(vec.w), forKey: "\(forPrefix)_w")
    }

    func decode_simd_float4x4(prefix: String) -> simd_float4x4 {
        let col0 = self.decode_simd_float4(prefix: "\(prefix)_0")
        let col1 = self.decode_simd_float4(prefix: "\(prefix)_1")
        let col2 = self.decode_simd_float4(prefix: "\(prefix)_2")
        let col3 = self.decode_simd_float4(prefix: "\(prefix)_3")

        return simd_float4x4(col0, col1, col2, col3)
    }

    func encode(_ mat: simd_float4x4, forPrefix: String) {
        self.encode(mat[0], forPrefix: "\(forPrefix)_0")
        self.encode(mat[1], forPrefix: "\(forPrefix)_1")
        self.encode(mat[2], forPrefix: "\(forPrefix)_2")
        self.encode(mat[3], forPrefix: "\(forPrefix)_3")
    }
}
