//
//  ElevationProjectedMiniWorldRender.swift
//  CavernSeer
//
//  Created by Samuel Grush on 11/7/20.
//  Copyright © 2020 Samuel K. Grush. All rights reserved.
//

import SwiftUI /// View
import SceneKit /// SCN*

protocol SCNRenderObserver {
    func renderObserver(renderer: SCNSceneRenderer)
}

struct ElevationProjectedMiniWorldRender: View {

    var scan: ScanFile
    var settings: SettingsStore

    var barSubview: AnyView? = nil

    var depthOfField: Double? = nil

    var selection: SurveyStation?

    var observer: SCNRenderObserver?

    var showUI: Bool = true

    @State
    private var prevSelection: SurveyStation?

    @State
    private var scaleBarModel = ScaleBarModel()

    /**
     * The rotation of the perspective, in degrees from magnetic north.
     *
     * Doing manual rotation rather than leaving it up to a value-binding seems to provide
     * more consistently, especially since we want to clamp the rotation to `[0, 360)`.
     */
    @State
    private var rotation: Int = 0

    /**
     * Communicate to the controller to step forward / backward by this many meters
     */
    @State
    private var fly: Int = 0

    @ObservedObject
    private var snapshotModel = SnapshotExportModel()
    @ObservedObject
    private var renderModel = GeneralRenderModel()

    var body: some View {
        VStack {
            ZStack {
                ElevationProjectedMiniWorldRenderController(
                    rotation: $rotation,
                    depthOfField: depthOfField,
                    fly: $fly,
                    renderModel: _renderModel,
                    snapshotModel: _snapshotModel,
                    selection: selection,
                    prevSelection: $prevSelection,
                    observer: observer,
                    scaleBarModel: $scaleBarModel,
                    showUI: showUI
                )
            }

            if self.showUI {
                HStack {
                    Spacer()

                    HStack {
                        RotationControls(rotation: $rotation)
                    }

                    Spacer()

                    HStack {
                        Button(action: { fly += 1 }) {
                            Image(systemName: "arrow.up.square")
                        }
                        Text("depth")
                        Button(action: { fly -= 1 }) {
                            Image(systemName: "arrow.down.square")
                        }
                    }

                    Spacer()

                    barSubview

                    Spacer()
                }.padding(.bottom, 8)
            }
        }
        .snapshotMenus(for: _snapshotModel)
        .navigationBarItems(trailing: HStack {
            snapshotModel.promptButton(scan: scan)
            renderModel.doubleSidedButton()
        })
        .onAppear(perform: self.appeared)
    }

    private func appeared() {
        self.renderModel.updateScanAndSettings(scan: scan, settings: settings)
    }
}

fileprivate final class ElevationProjectedMiniWorldRenderController :
    UIViewController,
    BaseProjectedMiniWorldRenderController {

    private static let DefaultDepthOfField: Double = 1000

    let showUI: Bool

    var depthOfField: Double?
    @Binding
    var rotation: Int
    @Binding
    var fly: Int
    var selectedStation: SurveyStation?
    @Binding
    var prevSelected: SurveyStation?
    @Binding
    var scaleBarModel: ScaleBarModel
    @ObservedObject
    var snapshotModel: SnapshotExportModel
    @ObservedObject
    var renderModel: GeneralRenderModel
    var observer: SCNRenderObserver?

    init(
        rotation: Binding<Int>,
        depthOfField: Double?,
        fly: Binding<Int>,
        renderModel: ObservedObject<GeneralRenderModel>,
        snapshotModel: ObservedObject<SnapshotExportModel>,
        selection: SurveyStation?,
        prevSelection: Binding<SurveyStation?>,
        observer: SCNRenderObserver?,
        scaleBarModel: Binding<ScaleBarModel>,
        showUI: Bool
    ) {
        self.depthOfField = depthOfField
        self._rotation = rotation
        self._fly = fly
        self._renderModel = renderModel
        self._snapshotModel = snapshotModel
        self.selectedStation = selection
        self._prevSelected = prevSelection
        self.observer = observer
        self._scaleBarModel = scaleBarModel
        self.showUI = showUI

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func viewUpdater(uiView: SCNView) {
        let pov = uiView.pointOfView
        if pov != nil {
            let rotation = CGFloat(self.rotation)
            let angleRads = CGFloat.pi * rotation / 180

            let move = SCNAction.rotateTo(
                x: 0,
                y: -angleRads,
                z: 0,
                duration: 0.5,
                usesShortestUnitArc: true
            )
            pov!.runAction(move)

            let flyDist = CGFloat(self.fly)
            if flyDist != 0 {
                let by = SCNVector3(
                    flyDist * sin(angleRads),
                    0,
                    -flyDist * cos(angleRads)
                )
                let flyMove = SCNAction.move(by: by, duration: 0.5)
                pov!.runAction(flyMove)

                DispatchQueue.main.async {
                    self.fly = 0
                }
            }
            
            pov!.camera?.zFar = depthOfField ?? Self.DefaultDepthOfField
            pov!.camera?.fieldOfView = uiView.frame.size.width
        }

        self.snapshotModel.viewUpdaterHandler(
            scnView: uiView,
            overlay: self.scaleBarModel.scene
        )
    }

    func renderer(
        _ renderer: SCNSceneRenderer,
        willRenderScene scene: SCNScene,
        atTime time: TimeInterval
    ) {
        self.willRenderScene(renderer, scene: scene, atTime: time)
        self.observer?.renderObserver(renderer: renderer)
    }

    func makeaCamera() -> SCNNode {
        let camera = SCNCamera()
        camera.usesOrthographicProjection = true
        camera.orthographicScale = 1
        camera.projectionDirection = .horizontal
        camera.zNear = 0.1
        camera.zFar = depthOfField ?? Self.DefaultDepthOfField

        let cameraNode = SCNNode()
        cameraNode.camera = camera
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 0)

        return cameraNode
    }

    func postSceneAttachment(sceneView: SCNView) {
        sceneView.allowsCameraControl = true
        sceneView.defaultCameraController.interactionMode = .pan
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scaleBarModel.updateOverlay(bounds: view.frame)
    }
}
