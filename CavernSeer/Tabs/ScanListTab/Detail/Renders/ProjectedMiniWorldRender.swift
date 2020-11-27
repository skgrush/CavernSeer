//
//  ProjectedMiniWorldRender.swift
//  CavernSeer
//
//  Created by Samuel Grush on 7/11/20.
//  Copyright © 2020 Samuel K. Grush. All rights reserved.
//

import SwiftUI /// View
import SceneKit /// SCN*

struct ProjectedMiniWorldRender: View {

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
        return SCNVector3Make(-center.x, -center.y, -center.z)
    }

    @State
    private var height: Int = 0

    @ObservedObject
    private var snapshotModel = SnapshotExportModel()

    var body: some View {
        VStack {
            ProjectedMiniWorldRenderController(
                sceneNodes: sceneNodes,
                ambientColor: ambientColor,
                height: $height,
                snapshotModel: _snapshotModel,
                selection: $selection,
                prevSelection: $prevSelection,
                scaleBarModel: $scaleBarModel
            )
            HStack {
                Stepper("Height: \(height)m", value: $height)
                    .frame(maxWidth: 150)
            }
        }
        .sheet(isPresented: $snapshotModel.showPrompt) {
            SnapshotExportView(model: snapshotModel)
        }
        .navigationBarItems(trailing: snapshotModel.promptButton(scan: scan))
    }
}

final class ProjectedMiniWorldRenderController :
    UIViewController, BaseProjectedMiniWorldRenderController {

    let sceneNodes: [SCNNode]
    let ambientColor: Color?

    @Binding
    var height: Int
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
        height: Binding<Int>,
        snapshotModel: ObservedObject<SnapshotExportModel>,
        selection: Binding<SurveyStation?>,
        prevSelection: Binding<SurveyStation?>,
        scaleBarModel: Binding<ScaleBarModel>
    ) {
        self.sceneNodes = sceneNodes
        self.ambientColor = ambientColor
        _height = height
        _snapshotModel = snapshotModel
        _selectedStation = selection
        _prevSelected = prevSelection
        _scaleBarModel = scaleBarModel

        super.init(nibName: nil, bundle: nil)
    }


    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func postSceneAttachment(sceneView: SCNView) {
        sceneView.allowsCameraControl = true
        sceneView.defaultCameraController.interactionMode = .pan
    }

    func viewUpdater(uiView: SCNView) {
        let pov = uiView.pointOfView
        if pov != nil {
            let pos = pov!.position
            let move = SCNAction.moveBy(
                x: 0,
                y: CGFloat(Float(height) - pos.y),
                z: 0, duration: 0.5
            )
            pov!.runAction(move)

            pov!.camera?.fieldOfView = uiView.frame.size.width
        }

        if self.snapshotModel.multiplier != nil {
            self.snapshotModel.renderASnapshot(
                view: uiView,
                overlaySKScene: self.scaleBarModel.scene
            )
        }
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
        cameraNode.eulerAngles = SCNVector3Make(.pi / -2, 0, 0)

        return cameraNode
    }

    func renderer(
        _ renderer: SCNSceneRenderer,
        didRenderScene scene: SCNScene,
        atTime time: TimeInterval
    ) {
        self.updateOrthoScale(renderer)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scaleBarModel.updateOverlay(bounds: view.frame)
    }
}
