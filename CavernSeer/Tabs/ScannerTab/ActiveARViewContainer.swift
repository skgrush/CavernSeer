//
//  ActiveARViewContainer.swift
//  CavernSeer
//
//  Created by Samuel Grush on 1/18/21.
//  Copyright © 2021 Samuel K. Grush. All rights reserved.
//

import SwiftUI /// UIViewRepresentable
import RealityKit /// ARView

struct ActiveARViewContainer: UIViewRepresentable {
    weak var control: ScannerControlModel?

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        arView.backgroundColor = UIColor.systemBackground

        control?.model?.onViewAppear(arView: arView)
        return arView
    }

    func updateUIView(_ arView: ARView, context: Context) {
        guard let drawView = control?.model?.drawView else { return }

        drawView.frame = arView.frame
        drawView.updateConstraints()
        arView.bringSubviewToFront(drawView)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(control: self.control)
    }

    static func dismantleUIView(_ arView: ARView, coordinator: Coordinator) {
        arView.removeFromSuperview()
        coordinator.control?.scanDisappearing()
    }
}


extension ActiveARViewContainer {
    class Coordinator {
        weak var control: ScannerControlModel?

        init(control: ScannerControlModel?) {
            self.control = control
        }
    }
}
