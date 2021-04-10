//
//  DrawableProtocol.swift
//  CavernSeer
//
//  Created by Samuel Grush on 7/1/20.
//  Copyright © 2020 Samuel K. Grush. All rights reserved.
//

import Foundation
import UIKit /// for CGContext
import RealityKit /// for ARView

protocol Drawable {

    func draw(context: CGContext)
    func prepareToDraw(arView: ARView)
}

class DrawableContainer {
    var drawables: [Drawable] = []
}
