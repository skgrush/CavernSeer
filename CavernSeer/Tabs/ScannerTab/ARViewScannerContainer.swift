//
//  ARViewScannerContainer.swift
//  CavernSeer
//
//  Created by Samuel Grush on 6/28/20.
//  Copyright © 2020 Samuel K. Grush. All rights reserved.
//

import SwiftUI /// UIViewRepresentable, Context
import RealityKit /// ARView

struct ARViewScannerContainer : View {

    @EnvironmentObject
    var scanStore: ScanStore

    @ObservedObject
    var control: ScannerControlModel

    private var usePassiveCam: Bool {
        control.cameraEnabled != true ||
        !control.renderingARView ||
            control.model == nil
    }

    var body: some View {
        if usePassiveCam {
            PassiveCameraViewContainer(control: control)
        } else {
            ARViewScannerContainerInner(control: control)
        }
    }
}

fileprivate struct ARViewScannerContainerInner: UIViewRepresentable {
//    weak var scanModel: ScannerModel?
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
//        scanModel.updateDrawConstraints()
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


extension ARViewScannerContainerInner {
    class Coordinator {
        weak var control: ScannerControlModel?

        init(control: ScannerControlModel?) {
            self.control = control
        }
    }
}
