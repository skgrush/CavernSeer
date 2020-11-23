//
//  SettingsStore.swift
//  CavernSeer
//
//  Created by Samuel Grush on 11/15/20.
//  Copyright © 2020 Samuel K. Grush. All rights reserved.
//

import Foundation
import SwiftUI
import SceneKit


final class SettingsStore : NSObject, ObservableObject {
    static let lengthPrefs: [LengthPreference] = [
        .MetricMeter,
        .CustomaryFoot
    ]

    static let modes3d: [SCNInteractionMode] = [
        .fly,
        .orbitAngleMapping,
        .orbitArcball,
        .orbitCenteredArcball,
        .orbitTurntable,
        .pan,
        .truck,
    ]

    private let def = UserDefaults.standard

    @Published
    var ColorMesh: Color! {
        didSet { setValue(.ColorMesh, from: oldValue, to: ColorMesh) }
    }

    @Published
    var ColorMeshQuilt: Bool! {
        didSet { setValue(.ColorMeshQuilt, from: oldValue, to: ColorMeshQuilt) }
    }

    @Published
    var ColorLightAmbient: Color! {
        didSet {
            setValue(.ColorLightAmbient, from: oldValue, to: ColorLightAmbient)
        }
    }

    @Published
    var UnitsLength: LengthPreference! {
        didSet { setValue(.UnitsLength, from: oldValue, to: UnitsLength) }
    }

    @Published
    var InteractionMode3d: SCNInteractionMode! {
        didSet {
            setValue(.InteractionMode3d, from: oldValue, to: InteractionMode3d)
        }
    }

    private func setValue<ValT:Equatable>(
        _ key: SettingsKey,
        from oldValue: ValT,
        to newValue: ValT
    ) {
        if newValue != oldValue {
            do {
                let encoded = try key.encodeValue(value: newValue)
                def.set(
                    encoded,
                    forKey: key.rawValue
                )
            } catch {
                debugPrint(
                    "Call to updateValue with unknown:",
                    newValue
                )
            }
        }
    }

    override init() {
        /// register default values for our defaults
        def.register(defaults: getSettingsDefaultDictionary())

        super.init()

        let allKeys = SettingsKey.allCases.map { $0.rawValue }

        /// pull all values out of `UserDefaults` into our published properties
        self.updateValues(keys: allKeys)

        /// observe changes to all our values
        allKeys.forEach {
            key in
            def.addObserver(
                self,
                forKeyPath: key,
                options: .new,
                context: nil
            )
        }
    }

    deinit {
        SettingsKey.allCases.forEach {
            key in
            def.removeObserver(self, forKeyPath: key.rawValue)
        }
    }

    /**
     * KVO handler for changes to our keys in `UserDefaults`.
     */
    internal override func observeValue(
        forKeyPath keyPath: String?,
        of object: Any?,
        change: [NSKeyValueChangeKey : Any]?,
        context: UnsafeMutableRawPointer?
    ) {
        self.updateValues(keys: [keyPath])
    }

    /**
     * Updates the values of the provided keys with the values in `UserDefaults`.
     */
    private func updateValues(keys: [String?]) {

        keys.forEach {
            switch $0 {
                case SettingsKey.ColorMesh.rawValue:
                    self.ColorMesh = def.color(
                        forKey: SettingsKey.ColorMesh.rawValue
                    ) ?? (SettingsKey.ColorMesh.defaultValue as! Color)

                case SettingsKey.ColorMeshQuilt.rawValue:
                    self.ColorMeshQuilt = def.bool(
                        forKey: SettingsKey.ColorMeshQuilt.rawValue
                    )

                case SettingsKey.ColorLightAmbient.rawValue:
                    self.ColorLightAmbient = def.color(
                        forKey: SettingsKey.ColorLightAmbient.rawValue
                    ) ?? (SettingsKey.ColorLightAmbient.defaultValue as! Color)

                case SettingsKey.UnitsLength.rawValue:
                    let e = SettingsKey.UnitsLength
                    self.UnitsLength = LengthPreference(
                        rawValue: def.integer(forKey: e.rawValue)
                    ) ?? (e.defaultValue as! LengthPreference)

                case SettingsKey.InteractionMode3d.rawValue:
                    let e = SettingsKey.InteractionMode3d
                    self.InteractionMode3d = SCNInteractionMode(
                        rawValue: def.integer(forKey: e.rawValue)
                    ) ?? (e.defaultValue as! SCNInteractionMode)

                default:
                    debugPrint(
                        "Call to updateValue with unknown:",
                        $0 as Any
                    )
            }
        }
    }
}
