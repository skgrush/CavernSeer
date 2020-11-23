//
//  LengthPreferenceEnum.swift
//  CavernSeer
//
//  Created by Samuel Grush on 11/15/20.
//  Copyright © 2020 Samuel K. Grush. All rights reserved.
//

import Foundation

enum LengthPreference: Int, Identifiable, Equatable {

    case MetricMeter = 1
    case CustomaryFoot = 2

    var id: Int { rawValue }
}

extension LengthPreference {
    var name: String {
        switch self {
            case .MetricMeter:
                return "meters (m)"
            case .CustomaryFoot:
                    return "feet (′)"
        }
    }

    var unit: UnitLength {
        switch self {
            case .MetricMeter:
                return .meters
            case .CustomaryFoot:
                return .feet
        }
    }

    func convert(_ measure: Measurement<UnitLength>)
        -> Measurement<UnitLength>
    {
        measure.converted(to: self.unit)
    }
}
