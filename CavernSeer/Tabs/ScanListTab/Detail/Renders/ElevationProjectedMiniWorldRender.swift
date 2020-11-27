//
//  ElevationProjectedMiniWorldRender.swift
//  CavernSeer
//
//  Created by Samuel Grush on 11/7/20.
//  Copyright © 2020 Samuel K. Grush. All rights reserved.
//

import SwiftUI /// View
import SceneKit /// SCN*

struct ElevationProjectedMiniWorldRender: View {

    var scan: ScanFile

    var color: UIColor?
    var ambientColor: Color?
    var quiltMesh: Bool

    @Binding
    var selection: SurveyStation?

    @State
    private var prevSelection: SurveyStation?

    @State
    private var scaleBarModel = ScaleBarModel()

    private var sceneNodes: [SCNNode] {
        return scan.toSCNNodes(color: color, quilt: quiltMesh)
    }

    private var offset: SCNVector3 {
        let center = scan.center
        return SCNVector3(center)
    }

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

    var body: some View {
        VStack {
            ElevationProjectedMiniWorldRenderController(
                sceneNodes: sceneNodes,
                ambientColor: ambientColor,
                rotation: $rotation,
                fly: $fly,
                snapshotModel: _snapshotModel,
                selection: $selection,
                prevSelection: $prevSelection,
                scaleBarModel: $scaleBarModel
            )
            HStack {
                Spacer()

                HStack {
                    Stepper(
                        onIncrement: { clampRotation(+5) },
                        onDecrement: { clampRotation(-5) },
                        label: {
                            Text("\(rotation)ºN")
                            + Text("m").font(.system(size: 8)).baselineOffset(0)
                        }
                    )
                        .frame(maxWidth: 150)

                    Button(action: { clampRotation(-90) }) {
                        Image(systemName: "gobackward.90")
                    }
                    Button(action: { clampRotation(+90) }) {
                        Image(systemName: "goforward.90")
                    }
                }

                Spacer()

                HStack {
                    Button(action: { fly += 2 }) {
                        Image(systemName: "arrow.up.square")
                    }
                    Text("depth")
                    Button(action: { fly -= 2 }) {
                        Image(systemName: "arrow.down.square")
                    }
                }

                Spacer()
            }
        }
        .sheet(isPresented: $snapshotModel.showPrompt) {
            SnapshotExportView(model: snapshotModel)
        }
        .navigationBarItems(trailing: snapshotModel.promptButton(scan: scan))
    }

    /**
     * Clamp rotation to `[0,360)`, "overflowing" and "underflowing" on boundaries
     */
    private func clampRotation(_ delta: Int) {
        self.rotation = (self.rotation + delta + 360) % 360
    }
}

final class ElevationProjectedMiniWorldRenderController :
    UIViewController,
    BaseProjectedMiniWorldRenderController {

    let sceneNodes: [SCNNode]
    let ambientColor: Color?

    @Binding
    var rotation: Int
    @Binding
    var fly: Int
    @Binding
    var selectedStation: SurveyStation?
    @Binding
    var prevSelected: SurveyStation?
    @Binding
    var scaleBarModel: ScaleBarModel
    @ObservedObject
    var snapshotModel: SnapshotExportModel

    init(
        sceneNodes: [SCNNode],
        ambientColor: Color?,
        rotation: Binding<Int>,
        fly: Binding<Int>,
        snapshotModel: ObservedObject<SnapshotExportModel>,
        selection: Binding<SurveyStation?>,
        prevSelection: Binding<SurveyStation?>,
        scaleBarModel: Binding<ScaleBarModel>
    ) {
        self.sceneNodes = sceneNodes
        self.ambientColor = ambientColor
        _rotation = rotation
        _fly = fly
        _snapshotModel = snapshotModel
        _selectedStation = selection
        _prevSelected = prevSelection
        _scaleBarModel = scaleBarModel

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

            pov!.camera?.fieldOfView = uiView.frame.size.width
        }

        if self.snapshotModel.multiplier != nil {
            self.snapshotModel.renderASnapshot(
                view: uiView,
                overlaySKScene: self.scaleBarModel.scene
            )
        }
    }

    func renderer(
        _ renderer: SCNSceneRenderer,
        didRenderScene scene: SCNScene,
        atTime time: TimeInterval
    ) {
        self.updateOrthoScale(renderer)
    }

    func makeaCamera() -> SCNNode {
        let camera = SCNCamera()
        camera.usesOrthographicProjection = true
        camera.orthographicScale = 1
        camera.projectionDirection = .horizontal
        camera.zNear = 0.1
        camera.zFar = 1000

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
