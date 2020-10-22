//
//  MiniWorldRender.swift
//  CavernSeer
//
//  Created by Samuel Grush on 7/7/20.
//  Copyright © 2020 Samuel K. Grush. All rights reserved.
//

import SwiftUI
import SceneKit

struct MiniWorldRender: View {

    var scan: ScanFile

    var color: Color?
    var ambientColor: Color = Color.red

    private var sceneNodes: [SCNNode] {
        let uiColor: UIColor? = color == nil ? nil : UIColor(color!)
        return scan.toSCNNodes(color: uiColor)
    }

    var offset: SCNVector3 {
        let center = scan.center
        return SCNVector3Make(-center.x, -center.y, -center.z)
    }

    var body: some View {
        MiniWorldRenderController(
            sceneNodes: sceneNodes,
            ambientColor: ambientColor
        )
    }
}

final class MiniWorldRenderController :
    UIViewController, UIViewRepresentable, SCNSceneRendererDelegate {

    let sceneView = SCNView(frame: .zero)
    let sceneNodes: [SCNNode]
    let ambientColor: Color

    init(sceneNodes: [SCNNode], ambientColor: Color) {
        self.sceneNodes = sceneNodes
        self.ambientColor = ambientColor
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func makeUIView(context: Context) -> SCNView {
        sceneView.scene = makeaScene()

        sceneView.showsStatistics = true

        sceneView.delegate = self

        sceneView.allowsCameraControl = true
        sceneView.defaultCameraController.interactionMode = .orbitAngleMapping
        sceneView.autoenablesDefaultLighting = true
        sceneView.isPlaying = true

        return sceneView
    }

    func updateUIView(_ uiView: SCNView, context: Context) {
    }

    private func makeaScene() -> SCNScene {
        let scene = SCNScene()

        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(x: 0, y: 10, z: 35)

        scene.rootNode.addChildNode(cameraNode)

        sceneNodes.forEach {
            node in
                // node.geometry?.firstMaterial?.diffuse.contents = UIColor.green
                scene.rootNode.addChildNode(node)
        }

        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light!.type = .ambient
        ambientLightNode.light!.color = UIColor(ambientColor)
        scene.rootNode.addChildNode(ambientLightNode)

        return scene
    }
}
