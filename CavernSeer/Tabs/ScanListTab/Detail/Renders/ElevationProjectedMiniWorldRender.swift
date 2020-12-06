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
    func observationUpdated(view: SCNView)
}

struct ElevationProjectedMiniWorldRender: View {

    var scan: ScanFile

    var color: UIColor?
    var ambientColor: Color?
    var quiltMesh: Bool

    var barSubview: AnyView? = nil

    var depthOfField: Double? = nil

    var selection: SurveyStation?

    var observer: SCNRenderObserver?

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
            ZStack {
                ElevationProjectedMiniWorldRenderController(
                    sceneNodes: sceneNodes,
                    ambientColor: ambientColor,
                    rotation: $rotation,
                    depthOfField: depthOfField,
                    fly: $fly,
                    snapshotModel: _snapshotModel,
                    selection: selection,
                    prevSelection: $prevSelection,
                    observer: observer,
                    scaleBarModel: $scaleBarModel
                )
            }
            HStack {
                Spacer()

                HStack {
                    RotationControls(rotation: $rotation)
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

                barSubview

                Spacer()
            }
        }
        .sheet(isPresented: $snapshotModel.showPrompt) {
            SnapshotExportView(model: snapshotModel)
        }
        .navigationBarItems(trailing: snapshotModel.promptButton(scan: scan))
    }
}

fileprivate final class ElevationProjectedMiniWorldRenderController :
    UIViewController,
    BaseProjectedMiniWorldRenderController {

    private static let DefaultDepthOfField: Double = 1000

    let sceneNodes: [SCNNode]
    let ambientColor: Color?

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
    var observer: SCNRenderObserver?

    init(
        sceneNodes: [SCNNode],
        ambientColor: Color?,
        rotation: Binding<Int>,
        depthOfField: Double?,
        fly: Binding<Int>,
        snapshotModel: ObservedObject<SnapshotExportModel>,
        selection: SurveyStation?,
        prevSelection: Binding<SurveyStation?>,
        observer: SCNRenderObserver?,
        scaleBarModel: Binding<ScaleBarModel>
    ) {
        self.sceneNodes = sceneNodes
        self.ambientColor = ambientColor
        self.depthOfField = depthOfField
        self._rotation = rotation
        self._fly = fly
        self._snapshotModel = snapshotModel
        self.selectedStation = selection
        self._prevSelected = prevSelection
        self.observer = observer
        self._scaleBarModel = scaleBarModel

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
