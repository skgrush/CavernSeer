//
//  ElevationCrossSectionRender.swift
//  CavernSeer
//
//  Created by Samuel Grush on 12/3/20.
//  Copyright © 2020 Samuel K. Grush. All rights reserved.
//

import SwiftUI
import SceneKit

class PlanRenderInsetIntoElevation : SCNDrawSubview, SCNRenderObserver {

    private weak var view: SCNView? = nil

//    private var cameraPosition: simd_float3?
//    private var cameraRotation: simd_float4?
//    private var cameraRight: simd_float3?

    private var left: SCNVector3?
    private var right: SCNVector3?


    /**
     * Plan view made.
     */
    override func parentMade(view: SCNView) {
//        self.view = view
        view.addSubview(self)

//        NSLayoutConstraint.activate([
//            self.topAnchor.constraint(equalTo: view.topAnchor),
//            self.leadingAnchor.constraint(equalTo: view.leadingAnchor),
//            self.trailingAnchor.constraint(equalTo: view.trailingAnchor),
//            self.bottomAnchor.constraint(equalTo: view.bottomAnchor),
//        ])
    }

    /**
     * Plan view updated.
     */
    override func parentUpdated(view: SCNView) {

    }

    /**
     * Plan view dismantled
     */
    override func parentDismantled(view: SCNView) {

    }

    func observationUpdated(view: SCNView) {
        if let pov = view.pointOfView {

//            self.cameraPosition = pov.simdPosition
//            self.cameraRotation = pov.simdRotation
//            self.cameraRight = pov.simdWorldRight

            let offset10 = 10 * pov.simdWorldRight
            let left = pov.simdPosition - offset10
            let right = pov.simdPosition + offset10

            self.left = SCNVector3(left.x, left.y, left.z)
            self.right = SCNVector3(right.x, right.y, right.z)
        }
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)

        defer { setNeedsDisplay() }

        if let context = UIGraphicsGetCurrentContext() {

            context.clear(bounds)
            context.setFillColor(UIColor.clear.cgColor)
            context.fill(bounds)

            self.alpha = 0.8

            context.setLineWidth(5)
            context.setStrokeColor(UIColor.black.cgColor)

            if
                let view = self.view,
//                let cameraPos = self.cameraPosition,
//                let cameraRot = self.cameraRotation,
//                let cameraRight = self.cameraRight
                let left = self.left,
                let right = self.right
            {
//                let offset10 = 10 * cameraRight
//
//                let left = cameraPos - offset10
//                let right = cameraPos + offset10
//
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
    private var observer = PlanRenderInsetIntoElevation()

    var body: some View {
        ZStack {
            PlanProjectedMiniWorldRender(
                scan: scan,
                color: color,
                ambientColor: ambientColor,
                quiltMesh: quiltMesh,
                overlays: [observer]
            )
            .frame(width: 50, height: 50, alignment: .bottomTrailing)
            ElevationProjectedMiniWorldRender(
                scan: scan,
                color: color,
                ambientColor: ambientColor,
                quiltMesh: quiltMesh,
                barSubview: barSubview,
                depthOfField: depthOfField,
                observer: observer
            )
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
