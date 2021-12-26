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

    @EnvironmentObject
    var imageSharer: ShareSheetUtility

    var scan: ScanFile
    var settings: SettingsStore

    @ObservedObject
    private var snapshotModel = SnapshotExportModel()

    @ObservedObject
    private var renderModel = GeneralRenderModel()

    var body: some View {
        MiniWorldRenderController(
            renderModel: renderModel,
            snapshotModel: snapshotModel
        )
        .snapshotMenus(for: _snapshotModel)
        .navigationBarItems(trailing: HStack {
            [unowned snapshotModel, unowned renderModel, unowned imageSharer] in
            snapshotModel.promptButton(scan: scan, sharer: imageSharer)
            renderModel.doubleSidedButton()
        })
        .onAppear(perform: self.appeared)
    }

    private func appeared() {
        self.renderModel.updateScanAndSettings(scan: scan, settings: settings)
    }
}

final class MiniWorldRenderController :
    UIViewController, UIViewRepresentable, SCNSceneRendererDelegate {

    unowned var snapshotModel: SnapshotExportModel
    unowned var renderModel: GeneralRenderModel

    init(
        renderModel: GeneralRenderModel,
        snapshotModel: SnapshotExportModel
    ) {
        self.renderModel = renderModel
        self.snapshotModel = snapshotModel
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
            self.renderModel.interactionMode3d
        sceneView.autoenablesDefaultLighting = true
        sceneView.isPlaying = true

        return sceneView
    }

    func updateUIView(_ uiView: SCNView, context: Context) {
        self.snapshotModel.viewUpdaterHandler(scnView: uiView)

        uiView.defaultCameraController.interactionMode =
            self.renderModel.interactionMode3d

        self.renderModel.viewUpdateHandler(scnView: uiView)
    }

    private func makeaScene() -> SCNScene {
        let scene = SCNScene()

        let cameraNode = SCNNode()
        cameraNode.name = "the-camera"
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(x: 0, y: 10, z: 35)

        scene.rootNode.addChildNode(cameraNode)


        renderModel.sceneNodes.forEach {
            node in
                scene.rootNode.addChildNode(node)
        }

        let ambientLightNode = SCNNode()
        ambientLightNode.name = "ambient-light"
        ambientLightNode.light = SCNLight()
        ambientLightNode.light!.type = .ambient
        if let ambientColor = renderModel.ambientColor {
            ambientLightNode.light!.color = ambientColor
        }
        scene.rootNode.addChildNode(ambientLightNode)

        return scene
    }
}
