//
//  ProjectedMiniWorldRender.swift
//  CavernSeer
//
//  Created by Samuel Grush on 7/11/20.
//  Copyright © 2020 Samuel K. Grush. All rights reserved.
//

import SceneKit
import SwiftUI

struct ProjectedMiniWorldRender: View {

    var scan: ScanFile

    private var sceneNodes: [SCNNode] {
        scan.toSCNNodes()
    }

    var offset: SCNVector3 {
        let center = scan.center
        return SCNVector3Make(-center.x, -center.y, -center.z)
    }

    var body: some View {
        ProjectedMiniWorldRenderController(sceneNodes: sceneNodes)
    }
}

final class ProjectedMiniWorldRenderController :
    UIViewController, UIViewRepresentable, SCNSceneRendererDelegate {

    let sceneView = SCNView(frame: .zero)
    let sceneNodes: [SCNNode]

    init(sceneNodes: [SCNNode]) {
        self.sceneNodes = sceneNodes
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
        sceneView.defaultCameraController.interactionMode = .pan
        sceneView.autoenablesDefaultLighting = true
        sceneView.isPlaying = true

        return sceneView
    }

    func updateUIView(_ uiView: SCNView, context: Context) {
    }

    private func makeaScene() -> SCNScene {
        let scene = SCNScene()

        let camera = SCNCamera()
        camera.usesOrthographicProjection = true
        camera.orthographicScale = 8

        let cameraNode = SCNNode()
        cameraNode.camera = camera
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 0)
        cameraNode.eulerAngles = SCNVector3Make(.pi / -2, 0, 0)

        scene.rootNode.addChildNode(cameraNode)

        sceneNodes.forEach {
            node in
                // node.geometry?.firstMaterial?.diffuse.contents = UIColor.green
                scene.rootNode.addChildNode(node)
        }

        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light!.type = .ambient
        ambientLightNode.light!.color = UIColor.red
        scene.rootNode.addChildNode(ambientLightNode)

        return scene
    }
}
