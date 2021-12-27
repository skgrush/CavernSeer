//
//  SnapshotExportView.swift
//  CavernSeer
//
//  Created by Samuel Grush on 11/8/20.
//  Copyright © 2020 Samuel K. Grush. All rights reserved.
//

import SwiftUI /// View
import SceneKit /// SCNView
import SpriteKit /// SKScene

class SnapshotExportModel : ObservableObject {
    fileprivate static let multipliers = [1, 2, 4, 8]

    private unowned var scan: ScanFile?
    private unowned var imageSharer: ShareSheetUtility?

    @Published
    fileprivate var promptShowing = false

    @Published
    private var multiplier: Int?

    /// Currently not in use due to some kind of issue with altert interactions
    @Published
    fileprivate var alertShowing = false
    @Published
    fileprivate var alertMessage = ""

    init(scan: ScanFile? = nil) {
        self.scan = scan
    }

    /**
     * Choose a `multiplier` value (or nil to cancel).
     * Expects that `viewUpdaterHandler` will be called next by the parent view.
     */
    func chooseSize(_ mult: Int?) {
        self.multiplier = mult
        self.promptShowing = false

        if mult != nil {
            self.alertMessage = "Size chosen"
            self.alertShowing = true
        } else {
            self.alertMessage = ""
            self.alertShowing = false
        }
    }

    /**
     * Should be called by the parent view on every update.
     * Will check if a snapshot is ready to be rendered.
     */
    func viewUpdaterHandler(scnView: SCNView, overlay: SKScene? = nil) {
        if self.multiplier != nil {
            self.renderASnapshot(view: scnView, overlay: overlay)
        }
    }

    private func renderASnapshot(view: SCNView, overlay: SKScene? = nil) {
        guard
            let multiplierInt = self.multiplier,
            let scan = self.scan,
            let sharer = self.imageSharer,
            let device = MTLCreateSystemDefaultDevice()
        else {
            debugPrint("renderASnapshot guard failed")
            self.chooseSize(nil)
            return
        }

        self.multiplier = nil
        self.alertMessage = "Rendering snapshot..."

        let multiplier = CGFloat(multiplierInt)
        let newSize = view.frame.size.applying(
            .init(scaleX: multiplier, y: multiplier)
        )

        let renderer = SCNRenderer(device: device)
        renderer.scene = view.scene
        renderer.pointOfView = view.pointOfView
        renderer.overlaySKScene = overlay
        renderer.autoenablesDefaultLighting = true

        let name = scan.name
            .replacingOccurrences(of: ":", with: "")
            .replacingOccurrences(of: "/", with: "")

        let img = renderer.snapshot(
            atTime: TimeInterval(0),
            with: newSize,
            antialiasingMode: .multisampling4X
        )

        do {
            try sharer.shareImage(img, type: .png, basename: name)
        } catch {
            debugPrint("Failed to write file \(error)")
            self.chooseSize(nil)
        }
    }

    func promptButton(scan: ScanFile, sharer: ShareSheetUtility) -> some View {
        self.scan = scan
        self.imageSharer = sharer
        return Button(action: {
            [weak self] in self?.promptShowing = true
        }) {
            Image(systemName: "camera.on.rectangle")
        }
    }
}


extension View {
    func snapshotMenus(
        for observable: ObservedObject<SnapshotExportModel>
    ) -> some View {
        let binding = observable.projectedValue
        unowned let model = observable.wrappedValue

        return self
            .actionSheet(isPresented: binding.promptShowing) {
                [unowned model] in
                ActionSheet(
                    title: Text("Export a scaled image"),
                    message: Text("Wait a few seconds for the render"),
                    buttons: Self.generateButtons(model)
                )
            }
    }

    fileprivate static func generateButtons(
        _ model: SnapshotExportModel
    ) -> [ActionSheet.Button] {
        let sz = UIScreen.main.bounds.size
        let width = Int(sz.width)
        let height = Int(sz.height)

        var btns = SnapshotExportModel.multipliers
            .map {
                mult in
                ActionSheet.Button.default(
                    Text("@\(mult)x (~\(mult * width)x\(mult * height))"),
                    action: { [unowned model] in model.chooseSize(mult) }
                )
            }

        btns.append(.cancel({ [unowned model] in model.chooseSize(nil) }))

        return btns
    }
}
