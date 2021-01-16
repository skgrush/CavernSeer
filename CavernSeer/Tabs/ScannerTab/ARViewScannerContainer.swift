//
//  ARViewScannerContainer.swift
//  CavernSeer
//
//  Created by Samuel Grush on 6/28/20.
//  Copyright © 2020 Samuel K. Grush. All rights reserved.
//

import SwiftUI /// UIViewRepresentable, Context
import RealityKit /// ARView

struct ARViewScannerContainer: UIViewRepresentable {
    weak var scanModel: ScannerModel?

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        arView.backgroundColor = UIColor.systemBackground

        scanModel?.onViewAppear(arView: arView)
        return arView
    }

    func updateUIView(_ arView: ARView, context: Context) {
        guard let drawView = scanModel?.drawView else { return }

        drawView.frame = arView.frame
//        scanModel.updateDrawConstraints()
        drawView.updateConstraints()
        arView.bringSubviewToFront(drawView)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(scanModel: self.scanModel)
    }

    static func dismantleUIView(_ arView: ARView, coordinator: Coordinator) {
        arView.removeFromSuperview()
        coordinator.scanModel?.onViewDisappear()
    }
}


extension ARViewScannerContainer {
    class Coordinator {
        weak var scanModel: ScannerModel?

        init(scanModel: ScannerModel?) {
            self.scanModel = scanModel
        }
    }
}
