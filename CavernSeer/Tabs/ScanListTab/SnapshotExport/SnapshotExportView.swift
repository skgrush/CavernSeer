//
//  SnapshotExportView.swift
//  CavernSeer
//
//  Created by Samuel Grush on 11/8/20.
//  Copyright © 2020 Samuel K. Grush. All rights reserved.
//

import SwiftUI /// View
import SceneKit /// SCNView

class SnapshotExportModel : ObservableObject {
    var scan: ScanFile?

    @Published
    var showPrompt = false

    @Published
    var multiplier: Int?

    @Published
    var exportUrl: URL?

    init(scan: ScanFile? = nil) {
        self.scan = scan

    }

    func replaceScan(scan: ScanFile?) {
        self.scan = scan
    }

    func renderASnapshot(view: SCNView, scaleBarModel: ScaleBarModel) {

        guard
            let multiplierInt = self.multiplier,
            let scan = self.scan,
            let device = MTLCreateSystemDefaultDevice()
        else {
            self.showPrompt = false
            self.multiplier = nil
            return
        }

        let multiplier = CGFloat(multiplierInt)
        let newSize = view.frame.size.applying(
            .init(scaleX: multiplier, y: multiplier)
        )

        let renderer = SCNRenderer(device: device)
        renderer.scene = view.scene
        renderer.pointOfView = view.pointOfView
        renderer.overlaySKScene = scaleBarModel.scene
        renderer.autoenablesDefaultLighting = true

        let temporaryDirectoryURL = FileManager.default.temporaryDirectory
        let name = scan.name
            .replacingOccurrences(of: ":", with: "")
            .replacingOccurrences(of: "/", with: "")

        let tempUrl = temporaryDirectoryURL
            .appendingPathComponent(name)
            .appendingPathExtension("png")

        let img = renderer.snapshot(
            atTime: TimeInterval(0),
            with: newSize,
            antialiasingMode: .multisampling4X
        )

        guard let imgData = img.pngData()
        else { fatalError("Failed to get pngData from snapshot") }

        try! imgData.write(to: tempUrl)

        self.exportUrl = tempUrl
        self.showPrompt = true
        self.multiplier = nil
    }
}


struct SnapshotExportView: View {

    @ObservedObject
    var model: SnapshotExportModel

    var body: some View {
        if model.exportUrl == nil {
            buttonStack
        } else {
            ScanShareSheet(activityItems: [model.exportUrl!])
                .onDisappear { model.exportUrl = nil }
        }
    }

    private var buttonStack: some View {
        let width = UIScreen.main.bounds.size.width
        return VStack {
            Button("@1x (~\(width)px)") {
                self.model.multiplier = 1
            }
            Button("@2x (~\(2*width)px)") {
                self.model.multiplier = 2
            }
            Button("@4x (~\(4*width)px)") {
                self.model.multiplier = 4
            }
            Button("@8x (~\(8*width)px)") {
                self.model.multiplier = 8
            }
        }
    }
}
