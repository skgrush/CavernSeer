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
    /** a `Color` */
    case ColorMesh
    /** a `Bool`, overrides `ColorMesh` if true */
    case ColorMeshQuilt
    /** a `Color` */
    case ColorLightAmbient

    /** a `LengthPreference` value */
    case UnitsLength

    /** an `SCNInteractionMode` */
    case InteractionMode3d
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

    var defaultValue: Any {
        switch self {
            case .ColorMesh:
                return Color.clear
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

    func encodeValue(value: Any) throws -> Any {
        switch self {
            case .ColorMesh, .ColorLightAmbient:
                return try NSKeyedArchiver.archivedData(
                    withRootObject: value as! Color,
                    requiringSecureCoding: false
                ) as Data
            case .ColorMeshQuilt:
                return value as! Bool

            case .UnitsLength:
                return (value as! LengthPreference).rawValue

            case .InteractionMode3d:
                return (value as! SCNInteractionMode).rawValue
        }
    }
}

func getSettingsDefaultDictionary() -> [String:Any] {
    var tups = [(String, Any)]()
    for aCase in SettingsKey.allCases {
        if let encoded = try? aCase.encodeValue(value: aCase.defaultValue) {
            tups.append((aCase.name, encoded))
        }
    }
    return [String:Any](uniqueKeysWithValues: tups)
}
