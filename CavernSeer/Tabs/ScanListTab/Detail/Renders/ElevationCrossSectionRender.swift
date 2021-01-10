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

fileprivate class CrossSectionPlanDrawOverlay :
    SCNDrawSubview, SCNRenderObserver {

    private weak var parentView: SCNView? = nil

    /// three points making up a 1m wide and 1m tall triangle pointing in the camera view's direction.
    private var centersAndForward: (SCNVector3, SCNVector3, SCNVector3)?
    /// points representing the left and right edges of the field of view
    private var leftAndRight: (SCNVector3, SCNVector3)?

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

        let center = pov.simdPosition
        let rightOffset10 = Float(scale) * pov.simdWorldRight
        let rightOffset0_5 = 0.5 * pov.simdWorldRight

        let left = center - rightOffset10
        let right = center + rightOffset10

        self.leftAndRight = (
            SCNVector3(left.x, left.y, left.z),
            SCNVector3(right.x, right.y, right.z)
        )

        let forward = center + pov.simdWorldFront
        let centerLeft = center - rightOffset0_5
        let centerRight = center + rightOffset0_5
        self.centersAndForward = (
            SCNVector3(centerLeft.x, centerLeft.y, centerLeft.z),
            SCNVector3(centerRight.x, centerRight.y, centerRight.z),
            SCNVector3(forward.x, forward.y, forward.z)
        )
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
                let (left, right) = self.leftAndRight,
                let (centerL, centerR, forward) = self.centersAndForward
            {

                self.projectAndDrawLines(
                    view: view,
                    ctx: context,
                    points: [
                        left,
                        centerL,
                        forward,
                        centerR,
                        right
                    ]
                )
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

    /**
     * Project the points into the view, then draw lines between them.
     *
     * Don't forget to line width and stroke color ahead of time!
     */
    private func projectAndDrawLines(
        view: SCNView,
        ctx: CGContext,
        points: [SCNVector3]
    ) {
        let projectedPoints = points
            .map { view.projectPoint($0) }
            .map { CGPoint(x: Double($0.x), y: Double($0.y)) }

        ctx.beginPath()
        ctx.addLines(between: projectedPoints)
        ctx.strokePath()
    }
}


struct ElevationCrossSectionRender: View {

    private static let CrossSectionDepth = 0.5

    var scan: ScanFile

    var color: UIColor?
    var ambientColor: Color?
    var quiltMesh: Bool
    var unitsLength: LengthPreference

    @State
    private var doCrossSection = false

    @State
    private var depthOfField: Double?

    @State
    private var dummyHeight = 100
    @State
    private var drawOverlay = CrossSectionPlanDrawOverlay()

    var body: some View {
        ZStack(alignment: .topTrailing) {
            ElevationProjectedMiniWorldRender(
                scan: scan,
                color: color,
                ambientColor: ambientColor,
                quiltMesh: quiltMesh,
                unitsLength: unitsLength,
                barSubview: barSubview,
                depthOfField: depthOfField,
                observer: drawOverlay
            )

            PlanProjectedMiniWorldRender(
                scan: scan,
                color: color,
                ambientColor: ambientColor,
                quiltMesh: quiltMesh,
                unitsLength: unitsLength,
                overlays: [drawOverlay],
                showUI: false,
                initialHeight: 20
            )
            .frame(width: 150, height: 150)
            .shadow(radius: 2)
            .border(Color.primary, width: 2)
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
