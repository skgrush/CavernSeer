//
//  Float+round.swift
//  CavernSeer
//
//  Created by Samuel Grush on 1/9/21.
//  Copyright © 2021 Samuel K. Grush. All rights reserved.
//

import Foundation

extension Float {
    func roundedTo(places: Int) -> Float {
        let adjuster = pow(10, Float(places))

        let raisedValue = (self * adjuster).rounded()
        return raisedValue / adjuster
    }
}

