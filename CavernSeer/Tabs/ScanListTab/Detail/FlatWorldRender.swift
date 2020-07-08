//
//  FlatWorldRender.swift
//  CavernSeer
//
//  Created by Samuel Grush on 7/7/20.
//  Copyright © 2020 Samuel K. Grush. All rights reserved.
//

import SwiftUI
import SpriteKit

struct FlatWorldRender: View {

    var scan: ScanFile

    var skNode: SKNode {
        scan.toSK3DNode()
    }

    var offset: CGPoint {
        let center = scan.center
        return CGPoint(x: CGFloat(center.x), y: CGFloat(center.y))
    }

    var body: some View {
        FlatWorldRenderController(
            skNode: skNode,
            offset: offset
        )
    }
}

final class FlatWorldRenderController :
    UIViewController, UIViewRepresentable, SKViewDelegate {

    let skView = SKView(frame: .zero)
    let skNode: SKNode
    let position: CGPoint

    init(skNode: SKNode, offset: CGPoint) {
        self.skNode = skNode
        self.position = offset

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func makeUIView(context: Context) -> SKView {

        skView.delegate = self

        skView.scene!.addChild(skNode)
        skView.isPaused = false

        return skView
    }

    func updateUIView(_ uiView: SKView, context: Context) {
    }
}
