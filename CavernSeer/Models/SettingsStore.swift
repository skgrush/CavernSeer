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
import Combine


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

    private var cancelBag = Set<AnyCancellable>()

    private let def = UserDefaults.standard

    @Published
    var ColorMesh: Color! {
        didSet { setValue(.ColorMesh, from: oldValue, to: ColorMesh!) }
    }

    @Published
    var ColorMeshQuilt: Bool! {
        didSet { setValue(.ColorMeshQuilt, from: oldValue, to: ColorMeshQuilt) }
    }

    @Published
    var ColorLightAmbient: Color! {
        didSet {
            setValue(.ColorLightAmbient, from: oldValue, to: ColorLightAmbient!)
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

    @Published
    var SortingMethod: SortMethod = .fileName {
        didSet {
            setValue(.SortingMethod, from: oldValue, to: SortingMethod)
        }
    }

    @Published
    var SortingOrder: SortOrder = .forward {
        didSet {
            setValue(.SortingOrder, from: oldValue, to: SortingOrder)
        }
    }

    @Published
    var formatter: NumberFormatter

    @Published
    var measureFormatter: MeasurementFormatter

    @Published
    var sortComparator: CacheSortComparator<ScanCacheFile> = .init(.fileName)

    let dateFormatter: DateFormatter

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
                    "Call to setValue with unknown:",
                    error.localizedDescription,
                    newValue
                )
            }
        }
    }

    override init() {
        /// register default values for our defaults
        def.register(defaults: getSettingsDefaultDictionary())

        (self.formatter, self.measureFormatter, self.dateFormatter) =
            Self.setupFormatters()

        super.init()

        let allKeys = SettingsKey.allCases.map { $0.rawValue }

        /// pull all values out of `UserDefaults` into our published properties
        self.updateValues(keys: allKeys)

        self.$SortingMethod.combineLatest(self.$SortingOrder)
            .sink { [self] method, order in
                self.sortComparator = .init(method, order)
            }
            .store(in: &cancelBag)

        self.sortComparator = .init(SortingMethod, SortingOrder)

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
            key in
            switch key {
                case SettingsKey.ColorMesh.rawValue:
                    if let val = def.uiColor(forKey: key!) {
                        self.ColorMesh = Color(val)
                    } else {
                        self.ColorMesh =
                            (SettingsKey.ColorMesh.defaultValue as! Color)
                    }

                case SettingsKey.ColorMeshQuilt.rawValue:
                    self.ColorMeshQuilt = def.bool(forKey: key!)

                case SettingsKey.ColorLightAmbient.rawValue:
                    if let val = def.uiColor(forKey: key!) {
                        self.ColorLightAmbient = Color(val)
                    } else {
                        self.ColorLightAmbient = (
                            SettingsKey.ColorLightAmbient.defaultValue as! Color
                        )
                    }

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

                case SettingsKey.SortingMethod.rawValue:
                    let e = SettingsKey.SortingMethod
                    self.SortingMethod = SortMethod(
                        rawValue: def.integer(forKey: e.rawValue)
                    ) ?? (e.defaultValue as! SortMethod)

                case SettingsKey.SortingOrder.rawValue:
                    let e = SettingsKey.SortingOrder
                    self.SortingOrder = SortOrder(
                        rawValue: def.integer(forKey: e.rawValue)
                    ) ?? (e.defaultValue as! SortOrder)

                default:
                    debugPrint(
                        "Call to updateValue with unknown:",
                        key as Any
                    )
            }
        }
    }

    private static func setupFormatters()
        -> (NumberFormatter, MeasurementFormatter, DateFormatter)
    {
        let locale = NSLocale.current

        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.allowsFloats = true
        formatter.maximumFractionDigits = 5
        formatter.usesGroupingSeparator = true
        formatter.groupingSize = 3

        let measurementFormatter = MeasurementFormatter()
        measurementFormatter.numberFormatter = formatter
        measurementFormatter.unitOptions = .providedUnit

        let dateFormatter = DateFormatter()
        dateFormatter.locale = locale
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .long

        return (formatter, measurementFormatter, dateFormatter)
    }
}
