//
//  ARViewScannerContainer.swift
//  CavernSeer
//
//  Created by Samuel Grush on 6/28/20.
//  Copyright © 2020 Samuel K. Grush. All rights reserved.
//

import SwiftUI
import RealityKit

struct ARViewScannerContainer: UIViewRepresentable {
    var scanModel: ScannerModel

    func makeUIView(context: Context) -> ARView {
        scanModel.arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {
        scanModel.drawView.frame = uiView.frame
        scanModel.updateDrawConstraints()
        scanModel.arView.bringSubviewToFront(scanModel.drawView)
    }
}
