//
//  CompassView.swift
//  CavernSeer
//
//  Created by Samuel Grush on 12/27/21.
//  Copyright © 2021 Samuel K. Grush. All rights reserved.
//

import SwiftUI
import CoreLocation

struct CompassView: View {

    static let degreeFormatter: NumberFormatter = {
        let n = NumberFormatter()
        n.locale = NSLocale.current
        n.minimumFractionDigits = 2
        n.maximumFractionDigits = 2
        return n
    }()

    @ObservedObject
    var heading = HeadingManager()

    @EnvironmentObject
    var settings: SettingsStore

    @State
    var degreeFormatter = MeasurementFormatter()

    var body: some View {
        VStack {
            if heading.headingIsAvailable == true {
                Text("\(formatDegree(heading.degrees))N")
                + Text("m").font(.system(size: 8)).baselineOffset(0)

                Text("±\(degreeFormatter.string(from: Measurement(value: heading.accuracy, unit: UnitAngle.degrees)))")
            } else {
                Text("???")
            }
        }
            .onAppear {
                heading.didAppear()
                setupDegreeFormatter()
            }
            .onDisappear { heading.didDisappear() }
    }

    private func formatDegree(_ degree: Double) -> String {
        degreeFormatter.string(from: Measurement(
            value: degree,
            unit: UnitAngle.degrees
        ))
    }

    private func setupDegreeFormatter() {
        let numberFmt = NumberFormatter()
        numberFmt.locale = settings.formatter.locale
        numberFmt.maximumFractionDigits = 2

        self.degreeFormatter.locale = settings.formatter.locale
        self.degreeFormatter.numberFormatter = numberFmt
        self.degreeFormatter.unitStyle = .short
    }

    class HeadingManager : NSObject, ObservableObject, CLLocationManagerDelegate {
        @Published
        var degrees: Double = 0
        @Published
        var trueDegrees: Double = 0
        @Published
        var accuracy: Double = .infinity

        @Published
        var headingIsAvailable: Bool?
        @Published
        var highPrecision: Bool?

        private let locationManager = CLLocationManager()

        override init() {
            super.init()

            self.locationManager.delegate = self
        }

        deinit {
    
        }

        func didAppear() {
            if CLLocationManager.headingAvailable() {
//                let initialAuth = self.locationManager.authorizationStatus
//                authChanged(self.locationManager)
//                switch initialAuth {
//                    case .notDetermined:
//                        self.locationManager.requestWhenInUseAuthorization()
//                    case .denied, .restricted:
//                        authChanged(self.locationManager)
//                    default:
//                        debugPrint("heading is already available")
//                }
                self.headingIsAvailable = true

                self.locationManager.pausesLocationUpdatesAutomatically = true
                self.locationManager.headingFilter = 0.8
                self.locationManager.startUpdatingHeading()

            } else {
                headingIsAvailable = false
            }
        }

        func didDisappear() {
            self.locationManager.stopUpdatingHeading()

        }

        func locationManager(
            _ manager: CLLocationManager,
            didUpdateHeading newHeading: CLHeading
        ) {
            if newHeading.magneticHeading < 0 {
                self.headingIsAvailable = false
            }

            self.degrees = newHeading.magneticHeading
            self.accuracy = newHeading.headingAccuracy
            self.trueDegrees = newHeading.trueHeading
        }

        func locationManagerShouldDisplayHeadingCalibration(
            _ manager: CLLocationManager
        ) -> Bool {
            true
        }
    }
}


#if DEBUG
struct CompassView_Previews: PreviewProvider {
    static var previews: some View {
        CompassView()
    }
}
#endif
