//
//  SettingsKeyEnum.swift
//  CavernSeer
//
//  Created by Samuel Grush on 11/15/20.
//  Copyright © 2021 Samuel K. Grush. All rights reserved.
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

    /** a `SortMethod` */
    case SortingMethod

    /** a `CSSortOrder` */
    case SortingOrder
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

            case .SortingMethod:
                return "Sorting method"
            case .SortingOrder:
                return "Sorting order"
        }
    }

    var defaultValue: Any {
        switch self {
            case .ColorMesh:
                return Color(UIColor.clear)
            case .ColorMeshQuilt:
                return false
            case .ColorLightAmbient:
                return Color(UIColor.red)

            case .UnitsLength:
                return LengthPreference.MetricMeter

            case .InteractionMode3d:
                return SCNInteractionMode.orbitAngleMapping

            case .SortingMethod:
                return SortMethod.fileName
            case .SortingOrder:
                return SortOrder.forward
        }
    }

    func encodeValue(value: Any) throws -> Any {
        switch self {
            case .ColorMesh, .ColorLightAmbient:
                return try NSKeyedArchiver.archivedData(
                    withRootObject: UIColor(value as! Color) as Any,
                    requiringSecureCoding: false
                ) as NSData
            case .ColorMeshQuilt:
                return value as! Bool

            case .UnitsLength:
                return (value as! LengthPreference).rawValue

            case .InteractionMode3d:
                return (value as! SCNInteractionMode).rawValue

            case .SortingMethod:
                return (value as! SortMethod).rawValue
            case .SortingOrder:
                return (value as! SortOrder).rawValue
        }
    }
}

func getSettingsDefaultDictionary() -> [String:Any] {
    [String:Any](
        uniqueKeysWithValues:
            SettingsKey.allCases.compactMap {
                if let encoded = try? $0.encodeValue(value: $0.defaultValue) {
                    return ($0.name, encoded)
                } else {
                    return nil as (String, Any)?
                }
            }
    )
}
