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
    weak var toDraw: DrawableContainer?

    init(frame: CGRect, toDraw: DrawableContainer) {
        self.toDraw = toDraw
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)

        guard let toDraw = self.toDraw else { return }

        defer { setNeedsDisplay() }

        if let context = UIGraphicsGetCurrentContext() {

            //if clearing {
            context.clear(bounds)
            context.setFillColor(UIColor.clear.cgColor)
            context.fill(bounds)
            //}

            self.alpha = 0.8

            context.setLineWidth(5)
            context.setStrokeColor(UIColor.red.cgColor)

            for drawable in toDraw.drawables {
                drawable.draw(context: context)
            }
        }
    }
}
