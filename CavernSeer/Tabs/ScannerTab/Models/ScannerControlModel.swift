//
//  ScannerControlModel.swift
//  CavernSeer
//
//  Created by Samuel Grush on 1/16/21.
//  Copyright © 2021 Samuel K. Grush. All rights reserved.
//

import Foundation
import Combine
import UIKit

class ScannerControlModel : ObservableObject {
    private var cancelBag = Set<AnyCancellable>()

    /** The active scanner model. Only accessible while scanning is enabled. */
    @Published
    public private(set) var model: ScannerModel?

    /** Controls if the `ActiveARViewContainer` will render. */
    @Published
    public private(set) var renderingARView = false

    /** Controls if the `PassiveCameraViewContainer` will render. */
    @Published
    public private(set) var renderingPassiveView = true

    /** Indicates that the UI should show us as being in scan-mode */
    @Published
    public private(set) var scanEnabled = false

    /** Indicates that the torch (onboard-light) is engaged. */
    @Published
    public private(set) var torchEnabled = false

    /** Indicates that the ARView debug should render. */
    @Published
    public private(set) var debugEnabled = false

    /** Indicates that the scene-understanding mesh should render. */
    @Published
    public private(set) var meshEnabled = false

    /** The user-facing message string. */
    @Published
    public private(set) var message = ""

    /** If we even have access to the camera. `nil` if not yet checked. */
    public private(set) var cameraEnabled: Bool?

    /** Controls the full screen presentation. `renderingARView` MUST be true if this is true.  */
    @Published
    public var fullscreenPresented = false

    init() {
        $renderingARView.sink { newValue in
            self.fullscreenPresented = newValue
        }.store(in: &cancelBag)

        /// if-and-only-if in fullscreen view, prevent the device from idling to sleep
        $fullscreenPresented.sink { presented in
            UIApplication.shared.isIdleTimerDisabled = presented
        }.store(in: &cancelBag)
    }

    /**
     * Stop the passive camera, construct a `ScannerModel` and start the active AR camera.
     */
    func startScan() {
        precondition(cameraEnabled == true)
        precondition(model == nil)
        precondition(renderingARView == false)

        self.message = ""

        self.renderingPassiveView = false

        self.model = ScannerModel(control: self)

        self.renderingARView = true
        self.scanEnabled = true

        /// now we wait for `model.onViewAppear` which will start the scan
    }

    /**
     * Closes the `fullScreenCover`, which stops rendering the ARView,
     * which causes the `ActiveARViewContainer` to disappear, which calls `scanDisappearing`,
     * which starts the rendering the passive view.
     *
     * Does  not save the scan.
     */
    func cancelScan() {
        if self.fullscreenPresented {
            self.fullscreenPresented = false
        }
        if self.scanEnabled {
            self.scanEnabled = false
        }
    }

    /**
     * Handler for when the active scan view is being dismantled.
     *
     * Calls the model's `onViewDisappear`, stops rendering the scan,
     * and enables the passive camera.
     */
    func scanDisappearing() {
        self.model?.onViewDisappear()

        self.cancelScan() /// should've been called already but just make sure

        self.model = nil
        self.torchEnabled = false

        self.renderingPassiveView = true
        self.renderingARView = false
    }

    /**
     * Call `saveScan` on the model, updating `message` as appropriate,
     * and cancel scan (returning to passive) when done.
     */
    func saveScan(scanStore: ScanStore) {
        guard let model = self.model
        else { fatalError("Call to saveScan() when no model is set") }

        model.saveScan(
            scanStore: scanStore,
            message: { msg in self.message = msg },
            done: { _ in self.cancelScan() }
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
}
