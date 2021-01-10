//
//  Double+round.swift
//  CavernSeer
//
//  Created by Samuel Grush on 1/9/21.
//  Copyright © 2021 Samuel K. Grush. All rights reserved.
//

import Foundation

extension Double {
    func roundedTo(places: Int) -> Double {
        let adjuster = pow(10, Double(places))

        let raisedValue = (self * adjuster).rounded()
        return raisedValue / adjuster
    }
}
