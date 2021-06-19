//
//  GeneralRenderModel.swift
//  CavernSeer
//
//  Created by Samuel Grush on 6/13/21.
//  Copyright © 2021 Samuel K. Grush. All rights reserved.
//

import Foundation
import SceneKit
import SwiftUI
import Combine

class GeneralRenderModel : ObservableObject {

    /// triggers changes in observers and indicates that changes have occurred
    @Published
    public private(set) var shouldUpdateView = false
    /// indicates that the sceneNodes have changed
    public private(set) var shouldUpdateNodes = false
    public private(set) var initialUpdate = true

    public private(set) var scan: ScanFile? = nil

    public private(set) var sceneNodes: [SCNNode] = []

    public private(set) var doubleSided = false

    // settings
    public private(set) var color: UIColor?
    public private(set) var ambientColor: UIColor?
    public private(set) var quiltMesh: Bool = false
    public private(set) var interactionMode3d: SCNInteractionMode = .orbitAngleMapping
    public private(set) var lengthPref: LengthPreference = .CustomaryFoot

    private var settings: SettingsStore? = nil
    private var settingsCancelBag = Set<AnyCancellable>()

    init() {
    }

    func doneUpdating() {
        self.shouldUpdateNodes = false
        self.shouldUpdateView = false
    }

    func toggleDoubleSided() {
        self.doubleSided = !self.doubleSided
        sceneNodes.forEach {
            $0.geometry?.firstMaterial?.isDoubleSided = doubleSided
        }
        shouldUpdateNodes = true
        shouldUpdateView = true
    }

    func setSettings(_ settings: SettingsStore) {
        self.settings = settings
        self.settingsCancelBag.removeAll()
        settings.$ColorMesh
            .sink {
                let cgColor = $0?.cgColor
                self.color = (cgColor != nil && cgColor!.alpha > 0.05)
                    ? UIColor(cgColor: cgColor!)
                    : nil
                self.updateColor()

            }
            .store(in: &settingsCancelBag)
        settings.$ColorLightAmbient
            .sink {
                color in
                self.ambientColor = color.map { UIColor($0) }
                self.updateColor()
            }
            .store(in: &settingsCancelBag)
        settings.$ColorMeshQuilt
            .sink {
                self.quiltMesh = $0 ?? self.quiltMesh
                self.updateColor()
            }
            .store(in: &settingsCancelBag)
        settings.$InteractionMode3d
            .sink {
                self.interactionMode3d = $0 ?? self.interactionMode3d
                self.shouldUpdateView = true
            }
            .store(in: &settingsCancelBag)
        settings.$UnitsLength
            .sink {
                self.lengthPref = $0 ?? self.lengthPref
                self.updateNodes()
            }
            .store(in: &settingsCancelBag)
    }

    func updateScanAndSettings(scan: ScanFile, settings: SettingsStore) {
        self.scan = scan
        self.setSettings(settings)
        self.updateNodes()
    }

    /**
     * Recreate the set of scene nodes.
     */
    private func updateNodes() {
        if scan != nil {
            sceneNodes = scan!.toSCNNodes(
                color: color,
                quilt: quiltMesh,
                lengthPref: lengthPref,
                doubleSided: doubleSided
            )
            self.shouldUpdateNodes = true
            self.shouldUpdateView = true
        }
    }

    private func updateColor() {

        shouldUpdateNodes = true
        shouldUpdateView = true
    }
}
