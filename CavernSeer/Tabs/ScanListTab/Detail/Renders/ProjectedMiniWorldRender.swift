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

    var color: Color?

    @Binding
    var selection: SurveyStation?

    @State
    private var prevSelection: SurveyStation?

    @State
    private var scaleBarModel = ScaleBarModel()

    private var sceneNodes: [SCNNode] {
        let uiColor: UIColor? = color == nil ? nil : UIColor(color!)
        return scan.toSCNNodes(color: uiColor)
    }

    private var offset: SCNVector3 {
        let center = scan.center
        return SCNVector3Make(-center.x, -center.y, -center.z)
    }

    @State
    private var height: Int = 0

    var body: some View {
        VStack {
            ProjectedMiniWorldRenderController(
                sceneNodes: sceneNodes,
                height: $height,
                selection: $selection,
                prevSelection: $prevSelection,
                scaleBarModel: $scaleBarModel
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

    static let defaultColor: UIColor = .gray
    static let selectedColor: UIColor = .blue

    let sceneView = SCNView(frame: .zero)
    let sceneNodes: [SCNNode]
    // let offset: SCNVector3

    @Binding
    var height: Int
    @Binding
    var selectedStation: SurveyStation?

    @Binding
    var prevSelected: SurveyStation?

    @Binding
    var scaleBarModel: ScaleBarModel

    init(
        sceneNodes: [SCNNode],
        height: Binding<Int>,
        selection: Binding<SurveyStation?>,
        prevSelection: Binding<SurveyStation?>,
        scaleBarModel: Binding<ScaleBarModel>
    ) {
        self.sceneNodes = sceneNodes
        // self.offset = offset
        _height = height
        _selectedStation = selection
        _prevSelected = prevSelection
        _scaleBarModel = scaleBarModel

        super.init(nibName: nil, bundle: nil)
    }


    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func makeUIView(context: Context) -> SCNView {
        let (scene, cameraNode) = makeaScene()
        sceneView.scene = scene
        sceneView.pointOfView = cameraNode

        sceneView.overlaySKScene = scaleBarModel.scene

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
            let move = SCNAction.moveBy(
                x: 0,
                y: CGFloat(Float(height) - pos.y),
                z: 0, duration: 0.5
            )
            pov!.runAction(move)

            pov!.camera?.fieldOfView = uiView.frame.size.width
        }

        if selectedStation != prevSelected {
            updateSelection(uiView: uiView)
        }

        scaleBarModel.updateOverlay(bounds: uiView.frame)
    }

    private func updateSelection(uiView: SCNView) {
        guard let scene = uiView.scene else { return }

        if prevSelected != nil {
            let previousNode = scene.rootNode.childNode(
                withName: prevSelected!.identifier.uuidString,
                recursively: false
            )
            previousNode?.geometry?.firstMaterial?.diffuse.contents =
                ProjectedMiniWorldRenderController.defaultColor
        }

        if selectedStation != nil {
            let node = scene.rootNode.childNode(
                withName: selectedStation!.identifier.uuidString,
                recursively: false
            )
            node?.geometry?.firstMaterial?.diffuse.contents =
                ProjectedMiniWorldRenderController.selectedColor
        }

        DispatchQueue.main.async {
            self.prevSelected = self.selectedStation
        }
    }

    private func makeaScene() -> (SCNScene, SCNNode) {
        let scene = SCNScene()

        let camera = SCNCamera()
        camera.usesOrthographicProjection = true
        camera.orthographicScale = 1
        camera.projectionDirection = .horizontal
        camera.fieldOfView = sceneView.frame.size.width
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

    func renderer(
        _ renderer: SCNSceneRenderer,
        didRenderScene scene: SCNScene,
        atTime time: TimeInterval
    ) {
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

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scaleBarModel.updateOverlay(bounds: view.frame)
    }
}
