//
//  SCNInteractionMode+name.swift
//  CavernSeer
//
//  Created by Samuel Grush on 11/22/20.
//  Copyright © 2020 Samuel K. Grush. All rights reserved.
//

import SceneKit

extension SCNInteractionMode {
    var name: String {
        switch self {
        case .fly:
            return "Fly"
        case .orbitTurntable:
            return "Orbit turntable"
        case .orbitAngleMapping:
            return "Orbit angle mapping"
        case .orbitCenteredArcball:
            return "Orbit centered arcball"
        case .orbitArcball:
            return "Orbit arcball"
        case .pan:
            return "Pan"
        case .truck:
            return "Truck"
        @unknown default:
            return "Unknown SCNInteractionMode \(rawValue)"
        }
    }
}
