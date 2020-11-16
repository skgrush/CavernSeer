//
//  BaseProjectedMiniWorldRender.swift
//  CavernSeer
//
//  Created by Samuel Grush on 11/7/20.
//  Copyright © 2020 Samuel K. Grush. All rights reserved.
//

import SwiftUI /// UIViewRepresentable
import SceneKit /// SCN*

protocol BaseProjectedMiniWorldRenderController :
    UIViewController, UIViewRepresentable, SCNSceneRendererDelegate {

    var sceneNodes: [SCNNode] { get }

    var selectedStation: SurveyStation? { get }
    var prevSelected: SurveyStation? { get set }
    var scaleBarModel: ScaleBarModel { get }

    func postSceneAttachment(sceneView: SCNView)

    func viewUpdater(uiView: SCNView)

    func makeaCamera() -> SCNNode
}


extension BaseProjectedMiniWorldRenderController {

    static var defaultColor: UIColor { .gray }
    static var selectedColor: UIColor { .blue }

    func makeUIView(context: Context) -> SCNView {
        let sceneView = SCNView(frame: .zero)
        let (scene, cameraNode) = makeaScene()
        sceneView.scene = scene
        sceneView.pointOfView = cameraNode

        sceneView.overlaySKScene = self.scaleBarModel.scene

        sceneView.showsStatistics = true

        sceneView.delegate = self

        self.postSceneAttachment(sceneView: sceneView)
        sceneView.autoenablesDefaultLighting = true
        sceneView.isPlaying = true
        sceneView.loops = true

        return sceneView
    }

    func updateUIView(_ uiView: SCNView, context: Context) {
        viewUpdater(uiView: uiView)

        if selectedStation != prevSelected {
            updateSelection(uiView: uiView)
        }

        uiView.delegate = self

        scaleBarModel.updateOverlay(bounds: uiView.frame)
    }

    func updateOrthoScale(_ renderer: SCNSceneRenderer) {
        if let camera = renderer.pointOfView?.camera {
            let orthoScale = camera.orthographicScale
            let scaleBar = self.scaleBarModel
            if (
                orthoScale != scaleBar.prevOrthoScale &&
                scaleBar.scene.size.width > 0
            ) {
                scaleBar.prevOrthoScale = orthoScale
                scaleBar.update(renderer: renderer)
            }
        }
    }

    func updateSelection(uiView: SCNView) {
        guard let scene = uiView.scene else { return }

        if prevSelected != nil {
            let previousNode = scene.rootNode.childNode(
                withName: prevSelected!.identifier.uuidString,
                recursively: false
            )
            previousNode?.geometry?.firstMaterial?.diffuse.contents =
                Self.defaultColor
        }

        if selectedStation != nil {
            let node = scene.rootNode.childNode(
                withName: selectedStation!.identifier.uuidString,
                recursively: false
            )
            node?.geometry?.firstMaterial?.diffuse.contents =
                Self.selectedColor
        }

        DispatchQueue.main.async {
            self.prevSelected = self.selectedStation
        }
    }

    func makeaScene() -> (SCNScene, SCNNode) {
        let scene = SCNScene()

        let cameraNode = self.makeaCamera()

        scene.rootNode.addChildNode(cameraNode)

        sceneNodes.forEach {
            node in
                // node.geometry?.firstMaterial?.diffuse.contents = UIColor.green
                scene.rootNode.addChildNode(node)
        }

        let ambientLightNode = makeAmbientLight()
        scene.rootNode.addChildNode(ambientLightNode)

        return (scene, cameraNode)
    }

    func makeAmbientLight() -> SCNNode {
        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light!.type = .ambient
        ambientLightNode.light!.color = UIColor.red
        return ambientLightNode
    }
}
