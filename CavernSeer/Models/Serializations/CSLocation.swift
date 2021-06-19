//
//  CSLocation.swift
//  CavernSeer
//
//  Created by Samuel Grush on 6/12/21.
//  Copyright © 2021 Samuel K. Grush. All rights reserved.
//

import Foundation
import CoreLocation

final class CSLocation : NSObject, NSSecureCoding {
    static let supportsSecureCoding = true

    let latitude: CLLocationDegrees
    let longitude: CLLocationDegrees
    let altitude: CLLocationDistance
    let horizontalAccuracy: CLLocationAccuracy
    let verticalAccuracy: CLLocationAccuracy
    let timestamp: Date
    let manuallyDefined: Bool

    convenience init(loc: CLLocation, manual: Bool) {
        self.init(
            latitude: loc.coordinate.latitude,
            longitude: loc.coordinate.longitude,
            altitude: loc.altitude,
            horizontalAccuracy: loc.horizontalAccuracy,
            verticalAccuracy: loc.verticalAccuracy,
            timestamp: loc.timestamp,
            manual: manual
        )
    }

    required init?(coder decoder: NSCoder) {
        self.latitude = decoder.decodeDouble(forKey: PropertyKeys.latitude)
        self.longitude = decoder.decodeDouble(forKey: PropertyKeys.longitude)
        self.altitude = decoder.decodeDouble(forKey: PropertyKeys.altitude)
        self.horizontalAccuracy = decoder.decodeDouble(
            forKey: PropertyKeys.horizontalAccuracy
        )
        self.verticalAccuracy = decoder.decodeDouble(
            forKey: PropertyKeys.verticalAccuracy
        )
        if let ts =  decoder.decodeObject(
            of: NSDate.self, forKey: PropertyKeys.timestamp
        ) {
            self.timestamp = ts as Date
        } else {
            return nil
        }
        self.manuallyDefined = decoder.decodeBool(
            forKey: PropertyKeys.manuallyDefined
        )
    }

    internal init(
        latitude: CLLocationDegrees,
        longitude: CLLocationDegrees,
        altitude: CLLocationDistance,
        horizontalAccuracy: CLLocationAccuracy,
        verticalAccuracy: CLLocationAccuracy,
        timestamp: Date,
        manual: Bool
    ) {
        self.latitude = latitude
        self.longitude = longitude
        self.altitude = altitude
        self.horizontalAccuracy = horizontalAccuracy
        self.verticalAccuracy = verticalAccuracy
        self.timestamp = timestamp
        self.manuallyDefined = manual
    }

    func encode(with coder: NSCoder) {
        coder.encode(latitude, forKey: PropertyKeys.latitude)
        coder.encode(longitude, forKey: PropertyKeys.longitude)
        coder.encode(altitude, forKey: PropertyKeys.altitude)
        coder.encode(horizontalAccuracy, forKey: PropertyKeys.horizontalAccuracy)
        coder.encode(verticalAccuracy, forKey: PropertyKeys.verticalAccuracy)
        coder.encode(timestamp, forKey: PropertyKeys.timestamp)
        coder.encode(manuallyDefined, forKey: PropertyKeys.manuallyDefined)

    }

    func toCLLocation() -> CLLocation {
        return CLLocation(
            coordinate: CLLocationCoordinate2D(
                latitude: latitude,
                longitude: longitude
            ),
            altitude: altitude,
            horizontalAccuracy: horizontalAccuracy,
            verticalAccuracy: verticalAccuracy,
            timestamp: timestamp
        )
    }
}

extension CSLocation {
    struct PropertyKeys {
        static let latitude = "latitude"
        static let longitude = "longitude"
        static let altitude = "altitude"
        static let horizontalAccuracy = "horizontalAccuracy"
        static let verticalAccuracy = "verticalAccuracy"
        static let timestamp = "timestamp"
        static let manuallyDefined = "manuallyDefined"
    }
}
