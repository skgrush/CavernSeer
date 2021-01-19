//
//  ScannerContainerView.swift
//  CavernSeer
//
//  Created by Samuel Grush on 6/28/20.
//  Copyright © 2020 Samuel K. Grush. All rights reserved.
//

import SwiftUI /// View

struct ScannerContainerView : View {

    @EnvironmentObject
    var scanStore: ScanStore

    @ObservedObject
    var control: ScannerControlModel

    var body: some View {
        if control.cameraEnabled != false {
            if control.renderingPassiveView {
                PassiveCameraViewContainer(control: control)
            } else if control.renderingARView {
                ActiveARViewContainer(control: control)
            }
        }
    }
}

