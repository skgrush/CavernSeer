//
//  ScannerModel.swift
//  CavernSeer
//
//  Created by Samuel Grush on 6/28/20.
//  Copyright © 2020 Samuel K. Grush. All rights reserved.
//

import Foundation
import ARKit /// for ARWorldTrackingConfiguration
import RealityKit /// for ARView
import Combine /// for Cancellable

final class ScannerModel: UIGestureRecognizer, ObservableObject {

    static let supportsScan =
        ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh)

    var sceneUpdateSubscription: Cancellable!

    /// the layer containing the AR render of the scan
    let arView: ARView
    /// the layer that can draw on top of the arView (e.g. for line drawing)
    let drawView: UIView

    @Published
    var message: String = ""
    @Published
    var scanEnabled: Bool! {
        didSet {
            if oldValue != scanEnabled {
                scanEnabled
                    ? self.startScan()
                    : self.stopScan()
            }
        }
    }
    @Published
    var showDebug: Bool! {
        didSet {
            if showDebug {
                arView.debugOptions.insert(.showStatistics)
            } else {
                arView.debugOptions.remove(.showStatistics)
            }
        }
    }

    /// snapshot at the beginning of a scan
    var startSnapshot: SnapshotAnchor?
    /// the current state of survey scans
    var surveyStations: [SurveyStationEntity] = []
    /// state manager for survey lines, currently the only Drawables in the scene
    var surveyLines = DrawableContainer()

    var scanConfiguration: ARWorldTrackingConfiguration!
    var passiveConfiguration: ARConfiguration!

    init() {

        let arView = ARView(frame: .zero)
        let drawView = DrawOverlay(frame: arView.frame, toDraw: surveyLines)
        self.arView = arView
        self.drawView = drawView

        super.init(target: arView, action: nil)

        setupARView()
        setupDrawView()
        sceneUpdateSubscription = arView.scene.subscribe(
            to: SceneEvents.Update.self
        ) {
            [unowned self] in self.updateScene(on: $0)
        }

        self.showDebug = false
        self.scanEnabled = false
    }

    func updateDrawConstraints() {
        NSLayoutConstraint.activate([
            drawView.topAnchor.constraint(equalTo: arView.topAnchor),
            drawView.leadingAnchor.constraint(equalTo: arView.leadingAnchor),
            drawView.trailingAnchor.constraint(equalTo: arView.trailingAnchor),
            drawView.bottomAnchor.constraint(equalTo: arView.bottomAnchor)
        ])
    }

    /// stop the scan and export all data to a `ScanFile`
    func showMesh(_ show: Bool) {
        if show {
            arView.debugOptions.insert(.showSceneUnderstanding)
        } else {
            arView.debugOptions.remove(.showSceneUnderstanding)
        }
    }

    func saveScan(scanStore: ScanStore) {
        self.message = "Starting save..."
        pause()

        let arView = self.arView
        let date = Date()

        arView.session.getCurrentWorldMap { worldMap, error in

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

            let lines = self.surveyLines.drawables.compactMap {
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
                try scanStore.saveScanFile(scanFile: scanFile)
                self.message = "Save successful!"
            } catch {
                self.message = "Error: \(error.localizedDescription)"
            }

            self.scanEnabled = false
        }
    }

    private func pause() {
        arView.session.pause()
    }

    private func unpause() {
        arView.session.run(arView.session.configuration!)
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

        showMesh(true)

        arView.environment.sceneUnderstanding.options = [
            .occlusion
        ]

        arView.session.run(
            scanConfiguration,
            options: [
                .resetSceneReconstruction,
                .removeExistingAnchors,
                .resetTracking
            ]
        )

        startSnapshot = SnapshotAnchor(capturing: arView, suffix: "start")

        setupGestures()
    }

    /// transfer to passive-mode, clearing the current state
    private func stopScan() {
        showMesh(false)

        arView.environment.sceneUnderstanding.options = []
        let clearingOptions: ARSession.RunOptions = [
            .resetSceneReconstruction,
            .removeExistingAnchors,
            .resetTracking
        ]

        if let currentConfig = arView.session.configuration {
            arView.session.run(currentConfig, options: clearingOptions)
        }

        arView.scene.anchors.removeAll()
        surveyStations.removeAll()
        surveyLines.drawables.removeAll()
        drawView.setNeedsDisplay()

        arView.session.run(passiveConfiguration, options: clearingOptions)

    }

    private func setupPassiveConfig() {
        passiveConfiguration = ARPositionalTrackingConfiguration()
    }

    private func setupScanConfig() {
        scanConfiguration = ARWorldTrackingConfiguration()
        scanConfiguration.sceneReconstruction = .mesh
        scanConfiguration.environmentTexturing = .none
        scanConfiguration.worldAlignment = .gravityAndHeading
    }

    private func setupARView() {
        arView.automaticallyConfigureSession = false
        arView.renderOptions = [
            .disablePersonOcclusion,
            .disableDepthOfField,
            .disableHDR,
            .disableMotionBlur,
        ]

        setupPassiveConfig()
        setupScanConfig()
    }

    private func setupDrawView() {
        drawView.translatesAutoresizingMaskIntoConstraints = false
        arView.addSubview(drawView)

        drawView.backgroundColor = UIColor.clear

        updateDrawConstraints()
    }



    private func updateScene(on event: SceneEvents.Update) {
        guard !surveyLines.drawables.isEmpty
        else { return }

        print("updating scene...")

        surveyLines.drawables.forEach {
            line in line.prepareToDraw(arView: arView)
        }
        drawView.setNeedsDisplay()
    }
}


/// +gestures
extension ScannerModel {
    func setupGestures() {
        let tapRecognizer = UITapGestureRecognizer(
            target: self,
            action: #selector(handleTap(_:))
        )
        arView.addGestureRecognizer(tapRecognizer)
    }

    @objc
    func handleTap(_ sender: UITapGestureRecognizer) {
        let tapLoc = sender.location(in: arView)

        let hitResult: [CollisionCastHit] = self.arView.hitTest(tapLoc)
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
        guard let raycast = self.arView.raycast(
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
        self.arView.scene.addAnchor(result)
        self.arView.installGestures(for: result)

        if lastEntity != nil {
            let line = lastEntity!.lineTo(result)
            surveyLines.drawables.append(line)
            line.updateProjections(arView: arView)
        }
    }
}
