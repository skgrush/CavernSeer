//
//  DrawOverlay.swift
//  CavernSeer
//
//  Created by Samuel Grush on 6/29/20.
//  Copyright © 2020 Samuel K. Grush. All rights reserved.
//

import Foundation
import UIKit /// UIView, CGRect

class DrawOverlay: UIView {

    var clearing = false
    var toDraw: DrawableContainer

    init(frame: CGRect, toDraw: DrawableContainer) {
        self.toDraw = toDraw
        super.init(frame: frame)
    }

    override init(frame: CGRect) {
        self.toDraw = DrawableContainer()
        super.init(frame: frame)
    }

    required init?(coder aDecoder: NSCoder) {
        self.toDraw = DrawableContainer()
        super.init(coder: aDecoder)
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)

        defer { setNeedsDisplay() }
        let context = UIGraphicsGetCurrentContext()

        if context != nil {

            //if clearing {
            context!.clear(bounds)
            context!.setFillColor(UIColor.clear.cgColor)
            context!.fill(bounds)
            //}

            self.alpha = 0.8

            context?.setLineWidth(5)
            context?.setStrokeColor(UIColor.red.cgColor)

            for drawable in toDraw.drawables {
                drawable.draw(context: context!)
            }
        }
    }
}
