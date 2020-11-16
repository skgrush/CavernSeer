//
//  ScaleBarModel.swift
//  CavernSeer
//
//  Created by Samuel Grush on 10/31/20.
//  Copyright © 2020 Samuel K. Grush. All rights reserved.
//

import Foundation
import SceneKit // SCNScene
import SpriteKit // SK*, simd_float3

final class ScaleBarModel: ObservableObject {

    static let ticks: [Double] = [1, 2, 5, 10, 25, 50, 100]
    static let subBarHeight = 10.0
    static let metersPerFoot = 0.3048
    static let borderSize = 1.0

    var prevOrthoScale = 0.0
    var scene: SKScene
    @Published
    var scalingFactor: Float

    init() {
        scene = SKScene()
        scalingFactor = 1
    }

    func updateOverlay(bounds: CGRect) {
        scene.size = bounds.size

        var bar = scene.childNode(withName: "scalebar") as? SKShapeNode
        if bar == nil {
            bar = SKShapeNode(rectOf: CGSize(width: bounds.width, height: 60))
            bar!.name = "scalebar"
            bar!.fillColor = .white
            bar!.position = CGPoint.zero
            scene.addChild(bar!)
        } else {
            bar!.path = CGPath(
                rect: CGRect(x: 0, y: 0, width: bounds.width, height: 60),
                transform: nil
            )
            bar!.position = CGPoint.zero
        }
    }

    func update(renderer: SCNSceneRenderer) {
        /** meters / 1pt */
        let metersPerPt = simd_distance(
            simd_double3(renderer.unprojectPoint(SCNVector3Make(0, 0, 0))),
            simd_double3(renderer.unprojectPoint(SCNVector3Make(1, 0, 0)))
        )

        if let bar = scene.childNode(withName: "scalebar") as? SKShapeNode {
            let offset = 2 * ScaleBarModel.borderSize

            let ptsPerMeter = 1 / metersPerPt
            let ptsPerFoot = ptsPerMeter * ScaleBarModel.metersPerFoot

            let metricBarPosY = 33.0
            let custoBarPosY =
                metricBarPosY +
                ScaleBarModel.subBarHeight +
                ScaleBarModel.borderSize

            bar.removeAllChildren()

            drawASubBar(
                bar: bar,
                subBarPosY: metricBarPosY,
                ptsPerUnit: ptsPerMeter,
                labelAbove: false,
                xOffset: offset
            )
            drawASubBar(
                bar: bar,
                subBarPosY: custoBarPosY,
                ptsPerUnit: ptsPerFoot,
                labelAbove: true,
                xOffset: offset
            )
        }
    }

    /**
     * - Parameter bar: the `SKNode` parent to attach elements to
     * - Parameter subBarPosY: the position of the sub-bar in the Y axis.
     * - Parameter ptsPerUnit: view-points per unit of measure, e.g. pts/meter
     */
    private func drawASubBar(
        bar: SKNode,
        subBarPosY: Double,
        ptsPerUnit: Double,
        labelAbove: Bool,
        xOffset: Double
    ) {
        let height = ScaleBarModel.subBarHeight
        let borderSize = ScaleBarModel.borderSize

        let maxXUnit = Double(bar.frame.width) / ptsPerUnit
        let lastTick = ScaleBarModel.ticks.last(where: {
            $0 < maxXUnit
        })

        if lastTick == nil {
            return
        }

        let subBarWidth = lastTick! * ptsPerUnit + 2 * borderSize
        let subBarBG = SKShapeNode(rectOf: CGSize(
            width: subBarWidth,
            height: height + 2 * borderSize
        ))
        subBarBG.fillColor = .black
        subBarBG.position = CGPoint(
            x: subBarWidth / 2 + xOffset - borderSize,
            y: subBarPosY
        )
        bar.addChild(subBarBG)

        let labelPosY = labelAbove
            ? subBarPosY + height * 0.5 + borderSize
            : subBarPosY - height * 1.5

        var lastX: Double = 0
        var lastColor = SKColor.black
        for tick in ScaleBarModel.ticks where tick <= lastTick! {
            let tickX = Double(tick) * ptsPerUnit

            let newSize = CGSize(
                width: tickX - lastX,
                height: height
            )
            let newBlockX = lastX + Double(newSize.width) / 2
            let newBlock = SKShapeNode(rectOf: newSize)
            lastColor = lastColor == SKColor.white ? .black : .white
            newBlock.fillColor = lastColor
            newBlock.position = CGPoint(
                x: newBlockX + xOffset,
                y: subBarPosY
            )
            bar.addChild(newBlock)

            let label = SKLabelNode(text: String(Int(tick)))
            label.position = CGPoint(
                x: tickX + xOffset,
                y: labelPosY
            )
            label.fontSize = CGFloat(height)
            label.fontColor = .black
            bar.addChild(label)

            lastX = tickX
        }
    }
}
