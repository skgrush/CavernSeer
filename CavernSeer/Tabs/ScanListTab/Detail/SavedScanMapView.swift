//
//  SavedScanMapView.swift
//  CavernSeer
//
//  Created by Samuel Grush on 7/18/21.
//  Copyright © 2021 Samuel K. Grush. All rights reserved.
//

import SwiftUI
import MapKit

fileprivate let usaLocation = MKCoordinateRegion(
    center: .init(latitude: 37.9559293, longitude: -91.7742682),
    latitudinalMeters: .init(2600),
    longitudinalMeters: .init(2600)
)

class SavedScanMapViewModel: ObservableObject {
    @Published
    var coordinateRegion: MKCoordinateRegion = usaLocation


    func update(location: CLLocation) {
        self.coordinateRegion.center = location.coordinate
        self.coordinateRegion.span = .init(
            latitudeDelta: 100,
            longitudeDelta: 100
        )
    }
}

struct SavedScanMapView: View {
    @State
    private var visible = false
    @State
    private var location: CLLocation? {
        didSet {
            if location != nil {
                model.update(location: location!)
            }
        }
    }

    @ObservedObject
    private var model = SavedScanMapViewModel()


    var body: some View {
        VStack {
            if visible {
                Map(coordinateRegion: $model.coordinateRegion)
                    .ignoresSafeArea()
            }
        }
        .onAppear(perform: { onAppear() })
        .onDisappear(perform: { self.visible = false })
    }

    private func onAppear() {
        self.visible = true
    }
}

struct SavedScanMapView_Previews: PreviewProvider {
    static var previews: some View {
        SavedScanMapView()
    }
}
