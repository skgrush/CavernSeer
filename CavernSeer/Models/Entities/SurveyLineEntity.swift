//
//  SurveyLineEntity.swift
//  CavernSeer
//
//  Created by Samuel Grush on 7/4/20.
//  Copyright © 2020 Samuel K. Grush. All rights reserved.
//

import Foundation
import RealityKit
import ARKit

class SurveyLineEntity: Entity, HasAnchoring, Drawable {

    /// entity the line starts at
    var start: Entity
    /// entity the line ends at
    var end: Entity

    /// projection of `start`'s position onto the view
    var startProjection: CGPoint?
    /// projection of `end`'s position onto the view
    var endProjection: CGPoint?

    init(start: Entity, end: Entity) {
        self.start = start
        self.end = end
        super.init()
    }

    required init() {
        fatalError("init() has not been implemented")
    }

    func updateProjections(arView: ARView) {
        guard
            let startAnchor = start.anchor,
            let endAnchor = end.anchor,
            let startProj = arView.project(startAnchor.position),
            let endProj = arView.project(endAnchor.position)
        else {
            return
        }

        self.startProjection = startProj
        self.endProjection = endProj
    }

    func prepareToDraw(arView: ARView) {
        updateProjections(arView: arView)
    }

    func draw(context: CGContext) {
        guard
            let startProj = startProjection,
            let endProj = endProjection
        else {
            return
        }

        context.beginPath()
        context.move(to: startProj)
        context.addLine(to: endProj)
        context.strokePath()
    }
}
