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

    var color: Color?

    private var sceneNodes: [SCNNode] {
        let uiColor: UIColor = color == nil ? .clear : UIColor(color!)
        return scan.toSCNNodes(color: uiColor)
    }

    var offset: SCNVector3 {
        let center = scan.center
        return SCNVector3Make(-center.x, -center.y, -center.z)
    }

    @State
    private var height: Int = 0

    var body: some View {
        VStack {
            ProjectedMiniWorldRenderController(
                sceneNodes: sceneNodes,
                height: $height
            )
            HStack {
                Stepper("Height: \(height)m", value: $height)
                    .frame(maxWidth: 150)
            }
        }
    }
}

final class ProjectedMiniWorldRenderController :
    UIViewController, UIViewRepresentable, SCNSceneRendererDelegate {

    let sceneView = SCNView(frame: .zero)
    let sceneNodes: [SCNNode]
    // let offset: SCNVector3
    @Binding
    var height: Int

    init(sceneNodes: [SCNNode], height: Binding<Int>) {
        self.sceneNodes = sceneNodes
        // self.offset = offset
        _height = height

        super.init(nibName: nil, bundle: nil)
    }


    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func makeUIView(context: Context) -> SCNView {
        let (scene, cameraNode) = makeaScene()
        sceneView.scene = scene
        sceneView.pointOfView = cameraNode

        sceneView.showsStatistics = true

        sceneView.delegate = self

        sceneView.allowsCameraControl = true
        sceneView.defaultCameraController.interactionMode = .pan
        sceneView.autoenablesDefaultLighting = true
        sceneView.isPlaying = true

        return sceneView
    }

    func updateUIView(_ uiView: SCNView, context: Context) {
        let pov = uiView.pointOfView
        if pov != nil {
            let pos = pov!.position
            let move = SCNAction.moveBy(x: 0, y: CGFloat(Float(height) - pos.y), z: 0, duration: 0)
            pov!.runAction(move)
        }
    }

    private func makeaScene() -> (SCNScene, SCNNode) {
        let scene = SCNScene()

        let camera = SCNCamera()
        camera.usesOrthographicProjection = true
        camera.orthographicScale = 16
        camera.zNear = 0.1
        camera.zFar = 1000

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

        return (scene, cameraNode)
    }
}
