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

    var showUI: Bool { get }

    var selectedStation: SurveyStation? { get }
    var prevSelected: SurveyStation? { get set }
    var scaleBarModel: ScaleBarModel { get }
    var renderModel: GeneralRenderModel { get }

    func postSceneAttachment(sceneView: SCNView)

    func viewUpdater(uiView: SCNView)

    func makeaCamera() -> SCNNode
}


extension BaseProjectedMiniWorldRenderController {

    static var defaultColor: UIColor { .gray }
    static var selectedColor: UIColor { .blue }

    static func dismantleUIView(_ uiView: SCNView, coordinator: Coordinator) {
        uiView.overlaySKScene = nil
    }

    func makeUIView(context: Context) -> SCNView {
        let sceneView = SCNView(frame: .zero)
        sceneView.backgroundColor = UIColor.systemBackground

        let (scene, cameraNode) = makeaScene()
        sceneView.scene = scene
        sceneView.pointOfView = cameraNode

        if self.showUI {
            sceneView.overlaySKScene = self.scaleBarModel.scene

            sceneView.showsStatistics = true
        }

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

        if self.showUI {
            scaleBarModel.updateOverlay(bounds: uiView.frame)
        }

        renderModel.viewUpdateHandler(scnView: uiView)
    }

    /**
     * Must be called by the implementer during rendering.
     */
    func willRenderScene(
        _ renderer: SCNSceneRenderer,
        scene: SCNScene,
        atTime time: TimeInterval
    ) {
        if self.showUI && self.scaleBarModel.scene.size.width == 0 {
            /// this really doesn't seem like the
            if let scn = renderer as? SCNView {
                DispatchQueue.main.async {
                    [unowned self] in
                    self.scaleBarModel.updateOverlay(bounds: scn.frame)
                }
            }
        }

        self.updateOrthoScale(renderer)
    }


    fileprivate func updateOrthoScale(_ renderer: SCNSceneRenderer) {
        guard self.showUI else { return }

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
        cameraNode.name = GeneralRenderModel.cameraNodeName

        scene.rootNode.addChildNode(cameraNode)

        renderModel.sceneNodes.forEach {
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
        ambientLightNode.name = GeneralRenderModel.ambientLightNodeName
        ambientLightNode.light = SCNLight()
        ambientLightNode.light!.type = .ambient
        if let ambientColor = renderModel.ambientColor {
            ambientLightNode.light!.color = ambientColor
        }
        return ambientLightNode
    }
}
