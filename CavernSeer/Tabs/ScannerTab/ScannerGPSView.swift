//
//  ScannerGPSView.swift
//  CavernSeer
//
//  Created by Samuel Grush on 12/27/21.
//  Copyright © 2021 Samuel K. Grush. All rights reserved.
//

import SwiftUI
import CoreLocation

struct ScannerGPSView: View {

    @ObservedObject
    var gps = GPSManager()

    @EnvironmentObject
    var settings: SettingsStore


    var body: some View {
        VStack {
            switch gps.status {
                case .unset:
                    Button(action: { gps.requestLocation() }) {
                        Image(systemName: "location")
                    }
                case .disabled:
                    Image(systemName: "location.slash")
                case .enabled:
                    LocationView(location: gps.location)
            }
        }
        .onAppear {
            gps.didAppear()

        }
        .onDisappear { gps.didDisappear() }
    }

    struct LocationView : View {

        var location: CLLocation

        @EnvironmentObject
        var settings: SettingsStore

        @State
        var shortLengthFormatter = MeasurementFormatter()

        var body: some View {
            VStack {
                Text("\(settings.formatCoordinate(location.coordinate.longitude))E")
                Text("\(settings.formatCoordinate(location.coordinate.latitude))N")
                Text("±\(formatMeters(location.horizontalAccuracy))")
            }
            .onAppear { setupFormatters() }
        }

        private func formatMeters(_ meters: Double) -> String {
            self.shortLengthFormatter.string(
                from: settings.UnitsLength.fromMetric(meters)
            )
        }

        private func setupFormatters() {
            let locale = settings.formatter.locale
            let ftNumFmt = NumberFormatter()
            ftNumFmt.locale = locale
            ftNumFmt.minimumFractionDigits = 1
            ftNumFmt.maximumFractionDigits = 1

            self.shortLengthFormatter.locale = locale
            self.shortLengthFormatter.numberFormatter = ftNumFmt
            self.shortLengthFormatter.unitOptions = .providedUnit

        }
    }


    enum GPSStatus {
        case unset
        case disabled
        case enabled
    }

    class GPSManager : NSObject, ObservableObject, CLLocationManagerDelegate {

        @Published
        var status = GPSStatus.unset

        @Published
        var location: CLLocation = .init(latitude: 0, longitude: 0)

        private let locationManager = CLLocationManager()

        override init() {
            super.init()

            self.locationManager.delegate = self
        }

        deinit {
            self.locationManager.delegate = nil
        }

        func didAppear() {
            updateStatus()
        }

        func didDisappear() {
            self.locationManager.stopUpdatingLocation()
        }

        func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
            self.updateStatus()
        }

        func locationManager(
            _ manager: CLLocationManager,
            didUpdateLocations locations: [CLLocation]
        ) {
            if let location = locations.last {
                self.location = location
            }
        }

        func requestLocation() {
            self.locationManager.requestWhenInUseAuthorization()
        }

        private func updateStatus() {
            if CLLocationManager.locationServicesEnabled() {
                switch self.locationManager.authorizationStatus {
                    case .authorizedAlways, .authorizedWhenInUse:
                        self.status = .enabled
                        self.locationManager.startUpdatingLocation()

                    case .restricted, .denied:
                        self.status = .disabled

                    default:
                        self.status = .unset
                }
            } else {
                self.status = .disabled
            }
        }
    }
}


#if DEBUG
struct ScannerGPS_Previews: PreviewProvider {
    static var previews: some View {
        ScannerGPSView()
    }
}
#endif
