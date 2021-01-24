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

final class ScannerModel:
    UIGestureRecognizer, ARSessionDelegate, ObservableObject
{

    static let supportsScan =
        ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh)

    static let supportsTorch = isTorchSupported()

    let clearingOptions: ARSession.RunOptions = [
        .resetSceneReconstruction,
        .removeExistingAnchors,
        .resetTracking,
        .stopTrackedRaycasts,
    ]

    #if !targetEnvironment(simulator)
    let showMeshOptions: ARView.DebugOptions = [
        .showSceneUnderstanding,
        .showWorldOrigin,
        .showAnchorGeometry,
        .showAnchorOrigins,
    ]
    #else
    let showMeshOptions: ARView.DebugOptions = []
    #endif

    /// the layer containing the AR render of the scan; owned by the `ScannerContainerView`
    weak var arView: ARView?
    /// the layer that can draw on top of the arView (e.g. for line drawing)
    weak var drawView: UIView?

    /// snapshot at the beginning of a scan
    var startSnapshot: SnapshotAnchor?
    /// the current state of survey scans
    var surveyStations: [SurveyStationEntity] = []
    /// state manager for survey lines, currently the only Drawables in the scene
    var surveyLines: DrawableContainer?

    var scanConfiguration: ARWorldTrackingConfiguration?

    private var tapRecognizer: UITapGestureRecognizer?
    private var cancelBag = Set<AnyCancellable>()

    init(control: ScannerControlModel) {

        super.init(target: nil, action: nil)

        control.$meshEnabled.sink {
            [weak self] (mesh) in self?.showMesh(mesh)
        }
        .store(in: &cancelBag)

        control.$debugEnabled.sink {
            [weak self] (dbg) in self?.showDebug(dbg)
        }
        .store(in: &cancelBag)

        control.$torchEnabled
            .dropFirst() /// ignore first so we don't default-on the torch
            .sink { (on) in Self.toggleTorch(on: on) }
            .store(in: &cancelBag)
    }

    func onViewAppear(arView: ARView) {
        let surveyLines = DrawableContainer()
        let drawView = DrawOverlay(frame: arView.frame, toDraw: surveyLines)

        self.arView = arView
        self.drawView = drawView
        self.surveyLines = surveyLines

        setupARView(arView: arView)
        setupDrawView(drawView: drawView, arView: arView)
        arView.scene.subscribe(
            to: SceneEvents.Update.self
        ) {
            [weak self] in self?.updateScene(on: $0)
        }
        .store(in: &cancelBag)

        setupScanConfig()

        self.startScan()
    }

    func onViewDisappear() {
        NSLayoutConstraint.deactivate(self.getConstraints())

        self.stopScan()

        self.cleanupGestures()

        self.drawView?.removeFromSuperview()

        #if !targetEnvironment(simulator)
        self.arView?.session.delegate = nil
        #endif
        self.arView?.scene.anchors.removeAll()
        self.arView = nil
        self.drawView = nil

        self.scanConfiguration = nil

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


    private func showDebug(_ show: Bool) {
        if show {
            arView?.debugOptions.insert(.showStatistics)
        } else {
            arView?.debugOptions.remove(.showStatistics)
        }
    }

    private func showMesh(_ show: Bool) {
        if show {
            arView?.debugOptions.formUnion(showMeshOptions)
        } else {
            arView?.debugOptions.subtract(showMeshOptions)
        }
    }

    /// stop the scan and export all data to a `ScanFile`
    func saveScan(
        scanStore: ScanStore,
        message: @escaping (_: String) -> Void,
        done: @escaping (_: Bool) -> Void
    ) {
        guard
            let arView = self.arView,
            let surveyLines = self.surveyLines
        else {
            done(false)
            return
        }

        message("Starting save...")
        pause()

        let startSnapshot = self.startSnapshot
        let stations = self.surveyStations
        let date = Date()

        #if !targetEnvironment(simulator)
        arView.session.getCurrentWorldMap { /* no self */ worldMap, error in

            message("Saving...")

            guard let map = worldMap
            else {
                message("WorldMap Error: \(error!.localizedDescription)")
                done(false)
                return
            }

            let endAnchor = SnapshotAnchor(
                capturing: arView.session,
                suffix: "end"
            )
            if endAnchor == nil {
                message("Failed to take snapshot")
            }

            let lines = surveyLines.drawables.compactMap {
                $0 as? SurveyLineEntity
            }

            let scanFile = ScanFile(
                map: map,
                startSnap: startSnapshot,
                endSnap: endAnchor,
                date: date,
                stations: stations,
                lines: lines)

            do {
                try scanStore.saveFile(file: scanFile)
                message("Save successful!")
                done(true)
            } catch {
                message("Error: \(error.localizedDescription)")
                done(false)
            }
        }
        #else
        done(false)
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

        #if !targetEnvironment(simulator)
        arView.environment.sceneUnderstanding.options = [
            .occlusion
        ]
        arView.session.run(
            scanConfiguration,
            options: self.clearingOptions
        )

        arView.session.delegate = self
        #endif

        setupGestures(arView: arView)
    }

    /// transfer to passive-mode, clearing the current state
    func stopScan() {
        guard
            let arView = self.arView,
            let drawView = self.drawView,
            let surveyLines = self.surveyLines
        else { return }

        self.pause()

        arView.scene.anchors.removeAll()
        surveyStations.removeAll()
        surveyLines.drawables.removeAll()
        drawView.setNeedsDisplay()
    }

    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        if self.startSnapshot == nil {
            self.startSnapshot = SnapshotAnchor(
                capturing: session,
                suffix: "start"
            )
        }
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

    private static func toggleTorch(on: Bool) {
        guard
            supportsTorch,
            let device = AVCaptureDevice.default(for: .video)
        else { return }

        do {
            let currentlyOn = device.isTorchActive
            let max = AVCaptureDevice.maxAvailableTorchLevel

            if currentlyOn != on {
                try device.lockForConfiguration()
                if on {
                    try device.setTorchModeOn(level: max)
                } else {
                    device.torchMode = .off
                }
                device.unlockForConfiguration()
            } else {

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
