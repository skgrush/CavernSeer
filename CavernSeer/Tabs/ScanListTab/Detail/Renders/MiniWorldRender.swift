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
    var settings: SettingsStore

    var offset: SCNVector3 {
        let center = scan.center
        return SCNVector3Make(-center.x, -center.y, -center.z)
    }

    @ObservedObject
    private var snapshotModel = SnapshotExportModel()

    @ObservedObject
    private var renderModel = GeneralRenderModel()

    var body: some View {
        MiniWorldRenderController(
            renderModel: _renderModel,
            snapshotModel: _snapshotModel
        )
        .snapshotMenus(for: _snapshotModel)
        .navigationBarItems(trailing: HStack {
            snapshotModel.promptButton(scan: scan)
            Button("doubleSided", action: { renderModel.toggleDoubleSided() })
        })
        .onAppear { appeared() }
    }

    private func appeared() {
        self.renderModel.updateScanAndSettings(scan: scan, settings: settings)
    }
}

final class MiniWorldRenderController :
    UIViewController, UIViewRepresentable, SCNSceneRendererDelegate {

    @ObservedObject
    var snapshotModel: SnapshotExportModel
    @ObservedObject
    var renderModel: GeneralRenderModel

    init(
        renderModel: ObservedObject<GeneralRenderModel>,
        snapshotModel: ObservedObject<SnapshotExportModel>
    ) {
        self._renderModel = renderModel
        self._snapshotModel = snapshotModel
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

        if self.renderModel.shouldUpdateView {

            if let ambientColor = self.renderModel.ambientColor {
                uiView.scene?.rootNode
                    .childNode(
                        withName: "ambient-light", recursively: false
                    )?.light?.color = ambientColor
            }

            if self.renderModel.shouldUpdateNodes {
                if let scene = uiView.scene {
                    scene.rootNode
                        .childNodes {
                            (node, _) in
                            node.name != "the-camera" && node.name != "ambient-light"
                        }
                        .forEach { $0.removeFromParentNode() }

                    let sceneNodes = self.renderModel.sceneNodes
                    if self.renderModel.quiltMesh {
                        sceneNodes.forEach {
                            $0.geometry?.firstMaterial?.diffuse.contents = UIColor(
                                hue: CGFloat(drand48()), saturation: 1, brightness: 1, alpha: 1
                            )
                        }
                    } else if let color = self.renderModel.color {
                        sceneNodes.forEach {
                            $0.geometry?.firstMaterial?.diffuse.contents = color
                        }
                    }

                    self.renderModel.sceneNodes.forEach {
                        scene.rootNode.addChildNode($0)
                    }

                    self.renderModel.doneUpdating()
                }
            } else {
                self.renderModel.doneUpdating()
            }
        }
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
