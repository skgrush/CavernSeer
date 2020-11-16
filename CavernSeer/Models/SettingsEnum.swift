//
//  SettingsEnum.swift
//  CavernSeer
//
//  Created by Samuel Grush on 11/15/20.
//  Copyright © 2020 Samuel K. Grush. All rights reserved.
//

import Foundation
import SwiftUI
import SceneKit


enum SettingsKey : String, CaseIterable {
    /** a `Color`(?), but can be `nil` */
    case ColorMesh = "Color_Mesh"
    /** a `Bool`, overrides `ColorMesh` if true */
    case ColorMeshQuilt = "Color_Mesh_Quilt"
    /** a `Color` (?) */
    case ColorLightAmbient = "Color_Light_Ambient"

    /** a `LengthPreference` value */
    case UnitsLength = "Units_Length"

    /** an `SCNInteractionMode` */
    case InteractionMode3d = "InteractionMode_3d"
}

extension SettingsKey {
    var name: String {
        switch self {
            case .ColorMesh:
                return "Mesh color"
            case .ColorMeshQuilt:
                return "Mesh random-quilt coloring"
            case .ColorLightAmbient:
                return "Ambient light color"

            case .UnitsLength:
                return "Unit of length"

            case .InteractionMode3d:
                return "3D render interaction mode"
        }
    }

    var defaultValue: Any? {
        switch self {
            case .ColorMesh:
                return nil
            case .ColorMeshQuilt:
                return false
            case .ColorLightAmbient:
                return Color.red

            case .UnitsLength:
                return LengthPreference.MetricMeter

            case .InteractionMode3d:
                return SCNInteractionMode.orbitAngleMapping
        }
    }
}

func getSettingsDefaultDictionary() -> [String:Any] {
    return [String:Any](
        uniqueKeysWithValues:
            SettingsKey.allCases.map {
                val in
                (val.name, val.defaultValue)
            }
    )
}
