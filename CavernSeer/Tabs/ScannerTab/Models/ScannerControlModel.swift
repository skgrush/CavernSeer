//
//  ScannerControlModel.swift
//  CavernSeer
//
//  Created by Samuel Grush on 1/16/21.
//  Copyright © 2021 Samuel K. Grush. All rights reserved.
//

import Foundation

class ScannerControlModel : ObservableObject {

//    weak var scanStore: ScanStore?

    @Published
    public private(set) var model: ScannerModel?

    @Published
    public private(set) var renderingARView = false

    @Published
    public private(set) var scanEnabled = false

    @Published
    public private(set) var torchEnabled = false

    @Published
    public private(set) var debugEnabled = false

    @Published
    public private(set) var meshEnabled = false

    @Published
    public private(set) var message = ""

    @Published
    public private(set) var passiveCameraEnabled = false

    public private(set) var cameraEnabled: Bool?

    func startScan() {
        precondition(cameraEnabled == true)
        precondition(model == nil)
        precondition(renderingARView == false)

        self.message = ""

        self.passiveCameraEnabled = false

        self.model = ScannerModel(control: self)

        self.renderingARView = true
        self.scanEnabled = true

        /// now we wait for `model.onViewAppear` which will start the scan
    }

    /**
     * Simply stops rendering the ARView, triggering the `ARViewScannerContainerInner` to
     * disappear, subsequently calling `scanDisappearing`
     */
    func cancelScan() {
        if self.renderingARView {
            self.renderingARView = false
        }
        if self.scanEnabled {
            self.scanEnabled = false
        }
    }

    func scanDisappearing() {
        self.model?.onViewDisappear()

        self.cancelScan() /// should've been called already but just make sure

        self.model = nil

        self.passiveCameraEnabled = true
    }

    func saveScan(scanStore: ScanStore) {
        guard let model = self.model
        else { fatalError("Call to saveScan() when no model is set") }

        model.saveScan(
            scanStore: scanStore,
            message: { self.message = $0 },
            done: self.saveScanDone
        )
    }

    func toggleTorch(_ enable: Bool) {
        self.torchEnabled = enable
    }

    func toggleDebug(_ enable: Bool) {
        self.debugEnabled = enable
    }

    func toggleMesh(_ enable: Bool) {
        self.meshEnabled = enable
    }

    func updateCameraAccess(hasAccess: Bool) {
        self.cameraEnabled = hasAccess
    }

    private func saveScanDone(_ success: Bool) {
        self.cancelScan()
    }
}
