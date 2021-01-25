//
//  MiniWorldRender.swift
//  CavernSeer
//
//  Created by Samuel Grush on 7/7/20.
//  Copyright © 2020 Samuel K. Grush. All rights reserved.
//

import SwiftUI /// View
import SceneKit /// SCN*

struct MiniWorldRender: View {

    var scan: ScanFile

    var color: UIColor?
    var ambientColor: Color?
    var quiltMesh: Bool
    var unitsLength: LengthPreference
    var interactionMode3d: SCNInteractionMode

    private var sceneNodes: [SCNNode] {
        return scan.toSCNNodes(
            color: color,
            quilt: quiltMesh,
            lengthPref: unitsLength
        )
    }

    var offset: SCNVector3 {
        let center = scan.center
        return SCNVector3Make(-center.x, -center.y, -center.z)
    }

    @ObservedObject
    private var snapshotModel = SnapshotExportModel()

    var body: some View {
        MiniWorldRenderController(
            sceneNodes: sceneNodes,
            snapshotModel: _snapshotModel,
            interactionMode: interactionMode3d,
            ambientColor: ambientColor
        )
        .sheet(isPresented: $snapshotModel.showPrompt) {
            SnapshotExportView(model: snapshotModel)
        }
        .navigationBarItems(trailing: snapshotModel.promptButton(scan: scan))
    }
}

final class MiniWorldRenderController :
    UIViewController, UIViewRepresentable, SCNSceneRendererDelegate {

    let sceneNodes: [SCNNode]
    let ambientColor: Color?

    @ObservedObject
    var snapshotModel: SnapshotExportModel

    var interactionMode: SCNInteractionMode

    init(
        sceneNodes: [SCNNode],
        snapshotModel: ObservedObject<SnapshotExportModel>,
        interactionMode: SCNInteractionMode,
        ambientColor: Color?
    ) {
        self.sceneNodes = sceneNodes
        self._snapshotModel = snapshotModel
        self.interactionMode = interactionMode
        self.ambientColor = ambientColor
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func makeUIView(context: Context) -> SCNView {
        let sceneView = SCNView(frame: .zero)
        sceneView.backgroundColor = UIColor.systemBackground

        sceneView.scene = makeaScene()

        sceneView.showsStatistics = true

        sceneView.delegate = self

        sceneView.allowsCameraControl = true
        sceneView.defaultCameraController.interactionMode =
            self.interactionMode
        sceneView.autoenablesDefaultLighting = true
        sceneView.isPlaying = true

        return sceneView
    }

    func updateUIView(_ uiView: SCNView, context: Context) {
        if self.snapshotModel.multiplier != nil {
            self.snapshotModel.renderASnapshot(
                view: uiView
            )
        }
        uiView.defaultCameraController.interactionMode = self.interactionMode
    }

    private func makeaScene() -> SCNScene {
        let scene = SCNScene()

        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(x: 0, y: 10, z: 35)

        scene.rootNode.addChildNode(cameraNode)

        sceneNodes.forEach {
            node in
                scene.rootNode.addChildNode(node)
        }

        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light!.type = .ambient
        if ambientColor != nil {
            ambientLightNode.light!.color = UIColor(ambientColor!)
        }
        scene.rootNode.addChildNode(ambientLightNode)

        return scene
    }
}
