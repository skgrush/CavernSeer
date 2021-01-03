//
//  ElevationCrossSectionRender.swift
//  CavernSeer
//
//  Created by Samuel Grush on 12/3/20.
//  Copyright © 2020 Samuel K. Grush. All rights reserved.
//

import SwiftUI
import SceneKit
import Combine /// Cancellable

class CrossSectionPlanDrawOverlay : SCNDrawSubview, SCNRenderObserver {

    private weak var parentView: SCNView? = nil

    private var left: SCNVector3?
    private var right: SCNVector3?

    private var previousScale: Double?
    private var previousPOV: simd_float4x4?

    private var previousParentScale: Double?
    private var previousParentPov: simd_float4x4?

    /**
     * The (parent) plan view was made.
     *
     * Add ourselves as a subview and wait for it to render.
     */
    override func parentMade(view: SCNView) {
        self.parentView = view

        self.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(self)

        self.backgroundColor = UIColor.clear

        self.constrainToParent()
    }

    /**
     * The (parent) plan view updated.
     */
    override func parentUpdated(view: SCNView) {

    }

    /**
     * The (parent) plan view rendered.
     *
     * If-and-only-if the parent's position or camera scale changed, we need to redraw the line.
     */
    override func parentRender(renderer: SCNSceneRenderer) {
        if
            let parentPov = renderer.pointOfView,
            let camera = parentPov.camera
        {
            let parentPovTx = parentPov.simdTransform
            let parentScale = camera.orthographicScale

            if (
                self.previousParentPov == nil ||
                !simd_equal(self.previousParentPov!, parentPovTx) ||
                self.previousParentScale != parentScale
            ) {
                self.previousParentPov = parentPovTx
                self.previousParentScale = parentScale

                DispatchQueue.main.async {
                    self.setNeedsDisplay()
                }
            }
        }
    }

    /**
     * The (parent) plan view dismantled
     */
    override func parentDismantled(view: SCNView) {

    }

    func renderObserver(renderer: SCNSceneRenderer) {
        if
            let pov = renderer.pointOfView,
            let camera = pov.camera
        {
            let povTx = pov.simdTransform
            let povScale = camera.orthographicScale

            if (
                self.previousPOV == nil ||
                !simd_equal(self.previousPOV!, povTx) ||
                self.previousScale != povScale
            ) {
                self.previousPOV = povTx
                self.previousScale = povScale
                self.updateLinePosition(pov: pov, scale: povScale)

                DispatchQueue.main.async {
                    self.setNeedsDisplay()
                }
            }
        }
    }

    private func updateLinePosition(pov: SCNNode, scale: Double) {

        let offset10 = Float(scale) * pov.simdWorldRight
        let left = pov.simdPosition - offset10
        let right = pov.simdPosition + offset10

        self.left = SCNVector3(left.x, left.y, left.z)
        self.right = SCNVector3(right.x, right.y, right.z)
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)

        if let context = UIGraphicsGetCurrentContext() {

            context.clear(bounds)

            self.alpha = 0.8

            context.setLineWidth(2)
            context.setStrokeColor(UIColor.black.cgColor)

            if
                let view = self.parentView,
                let left = self.left,
                let right = self.right
            {
                let projLeft = view.projectPoint(left)
                let projRight = view.projectPoint(right)


                context.beginPath()
                let start = CGPoint(
                    x: Double(projLeft.x),
                    y: Double(projLeft.y)
                )
                let end = CGPoint(
                    x: Double(projRight.x),
                    y: Double(projRight.y)
                )
                context.move(to: start)
                context.addLine(to: end)
                context.strokePath()
            }
        }
    }

    private func constrainToParent() {
        if let view = self.parentView {
            NSLayoutConstraint.activate([
                self.topAnchor.constraint(equalTo: view.topAnchor),
                self.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                self.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                self.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            ])
        }
    }
}


struct ElevationCrossSectionRender: View {

    private static let CrossSectionDepth = 0.5

    var scan: ScanFile

    var color: UIColor?
    var ambientColor: Color?
    var quiltMesh: Bool

    @State
    private var doCrossSection = false

    @State
    private var depthOfField: Double?

    @State
    private var dummyHeight = 100
    @State
    private var drawOverlay = CrossSectionPlanDrawOverlay()

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ElevationProjectedMiniWorldRender(
                scan: scan,
                color: color,
                ambientColor: ambientColor,
                quiltMesh: quiltMesh,
                barSubview: barSubview,
                depthOfField: depthOfField,
                observer: drawOverlay
            )

            PlanProjectedMiniWorldRender(
                scan: scan,
                color: color,
                ambientColor: ambientColor,
                quiltMesh: quiltMesh,
                overlays: [drawOverlay],
                showUI: false,
                initialHeight: 20
            )
            .frame(width: 150, height: 150, alignment: .bottomTrailing)
            .shadow(radius: 2)
            .border(Color.primary, width: 2)
            .offset(x: 0, y: -100)
        }
    }

    private var barSubview: AnyView {
        AnyView(
            Toggle("X", isOn: $doCrossSection)
                .frame(maxWidth: 50)
                .onChange(of: doCrossSection) {
                    x
                    in
                    depthOfField = x ? Self.CrossSectionDepth : nil
                }
        )
    }
}

//#if DEBUG
//struct ElevationCrossSectionRender_Previews: PreviewProvider {
//    static var previews: some View {
//        ElevationCrossSectionRender()
//    }
//}
//#endif
