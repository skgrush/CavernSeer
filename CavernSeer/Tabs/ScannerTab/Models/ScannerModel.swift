//
//  ScannerModel.swift
//  CavernSeer
//
//  Created by Samuel Grush on 6/28/20.
//  Copyright © 2020 Samuel K. Grush. All rights reserved.
//

import Foundation
import RealityKit /// ARView, SceneEvents
import ARKit /// other AR*, UIView, UIGestureRecognizer, NSLayoutConstraint
import Combine /// Cancellable

final class ScannerModel: UIGestureRecognizer, ObservableObject {

    static let supportsScan =
        ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh)

    static let supportsTorch = isTorchSupported()

    let clearingOptions: ARSession.RunOptions = [
        .resetSceneReconstruction,
        .removeExistingAnchors,
        .resetTracking,
        .stopTrackedRaycasts,
    ]

    var sceneUpdateSubscription: Cancellable?

    /// the layer containing the AR render of the scan; owned by the `ARViewScannerContainer`
    weak var arView: ARView?
    /// the layer that can draw on top of the arView (e.g. for line drawing)
    weak var drawView: UIView?

    @Published
    var message: String = ""
    @Published
    var scanEnabled: Bool = false {
        didSet {
            if oldValue != scanEnabled {
                scanEnabled
                    ? self.startScan()
                    : self.stopScan()
            }
        }
    }
    @Published
    var showDebug: Bool = false {
        didSet {
            if showDebug {
                arView?.debugOptions.insert(.showStatistics)
            } else {
                arView?.debugOptions.remove(.showStatistics)
            }
        }
    }
    @Published
    var meshEnabled: Bool = false {
        didSet {
            showMesh(meshEnabled)
        }
    }

    @Published
    var torchEnabled: Bool = false {
        didSet {
            toggleTorch(on: torchEnabled)
        }
    }

    /// snapshot at the beginning of a scan
    var startSnapshot: SnapshotAnchor?
    /// the current state of survey scans
    var surveyStations: [SurveyStationEntity] = []
    /// state manager for survey lines, currently the only Drawables in the scene
    var surveyLines: DrawableContainer?

    var scanConfiguration: ARWorldTrackingConfiguration?
    var passiveConfiguration: ARConfiguration?

    private var tapRecognizer: UITapGestureRecognizer?

    func onViewAppear(arView: ARView) {
        let surveyLines = DrawableContainer()
        let drawView = DrawOverlay(frame: arView.frame, toDraw: surveyLines)

        self.arView = arView
        self.drawView = drawView
        self.surveyLines = surveyLines

        setupARView(arView: arView)
        setupDrawView(drawView: drawView, arView: arView)
        sceneUpdateSubscription = arView.scene.subscribe(
            to: SceneEvents.Update.self
        ) {
            [weak self] in self?.updateScene(on: $0)
        }

        setupPassiveConfig()
        setupScanConfig()

        self.showDebug = false
        self.scanEnabled = false

        self.stopScan()
    }

    func onViewDisappear() {
        NSLayoutConstraint.deactivate(self.getConstraints())

        self.stopScan()

        self.sceneUpdateSubscription?.cancel()
        self.sceneUpdateSubscription = nil

        self.cleanupGestures()

        self.drawView?.removeFromSuperview()

        #if !targetEnvironment(simulator)
        self.arView?.session.delegate = nil
        #endif
        self.arView?.scene.anchors.removeAll()
        self.arView = nil
        self.drawView = nil

        self.scanConfiguration = nil
        self.passiveConfiguration = nil

        self.scanEnabled = false

        self.startSnapshot = nil
        self.surveyStations = []
        self.surveyLines = nil
    }

    private func getConstraints() -> [NSLayoutConstraint] {
        guard
            let arView = self.arView,
            let drawView = self.drawView
        else { return [] }

        return [
            drawView.topAnchor.constraint(equalTo: arView.topAnchor),
            drawView.leadingAnchor.constraint(equalTo: arView.leadingAnchor),
            drawView.trailingAnchor.constraint(equalTo: arView.trailingAnchor),
            drawView.bottomAnchor.constraint(equalTo: arView.bottomAnchor)
        ]
    }

    /// stop the scan and export all data to a `ScanFile`
    private func showMesh(_ show: Bool) {
        #if !targetEnvironment(simulator)
        if show {
            arView?.debugOptions.insert(.showSceneUnderstanding)
            arView?.debugOptions.insert(.showWorldOrigin)
            arView?.debugOptions.insert(.showAnchorGeometry)
            arView?.debugOptions.insert(.showAnchorOrigins)
        } else {
            arView?.debugOptions.remove(.showSceneUnderstanding)
            arView?.debugOptions.remove(.showWorldOrigin)
            arView?.debugOptions.remove(.showAnchorGeometry)
            arView?.debugOptions.remove(.showAnchorOrigins)
        }
        #endif
    }

    func saveScan(scanStore: ScanStore) {
        guard
            let arView = self.arView,
            let surveyLines = self.surveyLines
        else { return }

        self.message = "Starting save..."
        pause()

        let date = Date()

        #if !targetEnvironment(simulator)
        arView.session.getCurrentWorldMap { [weak self] worldMap, error in

            guard let self = self else { return }

            self.message = "Saving..."

            guard let map = worldMap
            else {
                    self.message
                        = "WorldMap Error: \(error!.localizedDescription)";
                    return
            }

            let endAnchor = SnapshotAnchor(capturing: arView, suffix: "end")
            if endAnchor == nil {
                self.message = "Failed to take snapshot"
            }

            let lines = surveyLines.drawables.compactMap {
                $0 as? SurveyLineEntity
            }

            let scanFile = ScanFile(
                map: map,
                startSnap: self.startSnapshot,
                endSnap: endAnchor,
                date: date,
                stations: self.surveyStations,
                lines: lines)

            do {
                try scanStore.saveFile(file: scanFile)
                self.message = "Save successful!"
            } catch {
                self.message = "Error: \(error.localizedDescription)"
            }

            self.scanEnabled = false
        }
        #else
        self.scanEnabled = false
        #endif
    }

    private func pause() {
        #if !targetEnvironment(simulator)
        arView?.session.pause()
        #endif
    }

    private func unpause() {
        #if !targetEnvironment(simulator)
        arView?.session.run(arView!.session.configuration!)
        #endif
    }

    /// Start a new scan with `scanConfiguration`
    private func startScan() {
        guard ScannerModel.supportsScan
        else {
            fatalError("""
                Scene reconstruction (for mesh generation) requires a device
                with a LiDAR Scanner, such as the fourth-generation iPad Pro.
            """)
        }
        guard
            let arView = self.arView,
            let scanConfiguration = self.scanConfiguration
        else { return }

        showMesh(self.meshEnabled)

        #if !targetEnvironment(simulator)
        arView.environment.sceneUnderstanding.options = [
            .occlusion
        ]
        arView.session.run(
            scanConfiguration,
            options: self.clearingOptions
        )
        #endif

        startSnapshot = SnapshotAnchor(capturing: arView, suffix: "start")

        setupGestures(arView: arView)
    }

    /// transfer to passive-mode, clearing the current state
    private func stopScan() {
        guard
            let arView = self.arView,
            let drawView = self.drawView,
            let surveyLines = self.surveyLines,
            let passiveConfiguration = self.passiveConfiguration
        else { return }

        self.pause()

        /// we must hide the mesh so it doesn't show between scans,
        /// BUT we _should_ persist the user's `meshEnabled` choice and reset to it next time
        self.showMesh(false)

        arView.scene.anchors.removeAll()
        surveyStations.removeAll()
        surveyLines.drawables.removeAll()
        drawView.setNeedsDisplay()

        #if !targetEnvironment(simulator)
        arView.session.run(passiveConfiguration, options: clearingOptions)
        #endif
    }

    private func setupPassiveConfig() {
        passiveConfiguration = ARPositionalTrackingConfiguration()
    }

    private func setupScanConfig() {
        scanConfiguration = ARWorldTrackingConfiguration()
        scanConfiguration!.sceneReconstruction = .mesh
        scanConfiguration!.environmentTexturing = .none
        scanConfiguration!.worldAlignment = .gravityAndHeading
    }

    private func setupARView(arView: ARView) {
        #if !targetEnvironment(simulator)
        arView.automaticallyConfigureSession = false
        arView.renderOptions = [
            .disablePersonOcclusion,
            .disableDepthOfField,
            .disableHDR,
            .disableMotionBlur,
        ]
        #endif
    }

    private func setupDrawView(drawView: DrawOverlay, arView: ARView) {
        drawView.translatesAutoresizingMaskIntoConstraints = false
        arView.addSubview(drawView)

        drawView.backgroundColor = UIColor.clear

        NSLayoutConstraint.activate(self.getConstraints())
    }



    private func updateScene(on event: SceneEvents.Update) {
        guard
            let arView = self.arView,
            let drawView = self.drawView,
            let surveyLines = self.surveyLines,
            !surveyLines.drawables.isEmpty
        else { return }

        print("updating scene...")

        surveyLines.drawables.forEach {
            line in line.prepareToDraw(arView: arView)
        }
        drawView.setNeedsDisplay()
    }

    private func toggleTorch(on: Bool) {
        guard
            Self.supportsTorch,
            let device = AVCaptureDevice.default(for: .video)
        else { return }

        do {
            try device.lockForConfiguration()

            if on {
                try device.setTorchModeOn(
                    level: AVCaptureDevice.maxAvailableTorchLevel
                )
            } else {
                device.torchMode = .off
            }

        } catch {
            fatalError("Failed to toggle torch, \(error.localizedDescription)")
        }
    }

    private static func isTorchSupported() -> Bool {
        guard let device = AVCaptureDevice.default(for: .video)
        else { return false }

        return device.hasTorch && device.isTorchModeSupported(.on)
    }
}


/// +gestures
extension ScannerModel {
    func setupGestures(arView: ARView) {
        let tapRecognizer = UITapGestureRecognizer(
            target: self,
            action: #selector(handleTap(_:))
        )
        arView.addGestureRecognizer(tapRecognizer)
        self.tapRecognizer = tapRecognizer
    }

    func cleanupGestures() {
        if
            let arView = self.arView,
            let tapRecog = self.tapRecognizer
        {
            arView.removeGestureRecognizer(tapRecog)
        }
        self.tapRecognizer = nil
    }

    @objc
    func handleTap(_ sender: UITapGestureRecognizer) {
        guard let arView = self.arView else { return }

        let tapLoc = sender.location(in: arView)

        let hitResult: [CollisionCastHit] = arView.hitTest(tapLoc)
        if let hitFirst = hitResult.first {
            tappedOnEntity(hitFirst: hitFirst)
            return
        } else {
            tappedOnNonentity(tapLoc: tapLoc)
        }


    }

    private func tappedOnEntity(hitFirst: CollisionCastHit) {
        let entity = hitFirst.entity
        if let stationEntity = entity as? SurveyStationEntity {
            stationEntity.highlight(true)
        }
    }

    private func tappedOnNonentity(tapLoc: CGPoint) {
        #if !targetEnvironment(simulator)
        guard
            let arView = self.arView,
            let surveyLines = self.surveyLines,
            let raycast = arView.raycast(
                from: tapLoc,
                allowing: .estimatedPlane,
                alignment: .any
            ).first
        else {
            return ///  no surface detected
        }

        let lastEntity = self.surveyStations.last

        let result = SurveyStationEntity(worldTransform: raycast.worldTransform)
        self.surveyStations.append(result)
        arView.scene.addAnchor(result)
        arView.installGestures(for: result)

        if lastEntity != nil {
            let line = lastEntity!.lineTo(result)
            surveyLines.drawables.append(line)
            line.updateProjections(arView: arView)
        }
        #endif
    }
}
