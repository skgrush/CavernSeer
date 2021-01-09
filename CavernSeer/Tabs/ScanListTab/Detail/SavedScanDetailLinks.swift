//
//  SavedScanDetailLinks.swift
//  CavernSeer
//
//  Created by Samuel Grush on 12/3/20.
//  Copyright © 2020 Samuel K. Grush. All rights reserved.
//

import SwiftUI

struct SavedScanDetailLinks: View {

    var model: SavedScanModel

    @EnvironmentObject
    var settings: SettingsStore

    private var meshColor: UIColor? {
        let cgColor = settings.ColorMesh?.cgColor
        if cgColor != nil && cgColor!.alpha > 0.05 {
            return UIColor(cgColor: cgColor!)
        }
        return nil
    }

    var body: some View {
        List {
            NavigationLink(
                destination: SavedScanDetailAdvanced(model: self.model)
            ) {
                HStack {
                    Text("Advanced")
                }
            }
            NavigationLink(
                destination: MiniWorldRender(
                    scan: self.model.scan,
                    color: meshColor,
                    ambientColor: settings.ColorLightAmbient,
                    quiltMesh: settings.ColorMeshQuilt
                )
            ) {
                HStack {
                    Text("3D Render")
                }
            }
            NavigationLink(
                destination: PlanProjectedMiniWorldRender(
                    scan: self.model.scan,
                    color: meshColor,
                    ambientColor: settings.ColorLightAmbient,
                    quiltMesh: settings.ColorMeshQuilt,
                    unitsLength: settings.UnitsLength
                )
            ) {
                HStack {
                    Text("Plan Projected Render")
                }
            }
            NavigationLink(
                destination: ElevationProjectedMiniWorldRender(
                    scan: self.model.scan,
                    color: meshColor,
                    ambientColor: settings.ColorLightAmbient,
                    quiltMesh: settings.ColorMeshQuilt,
                    unitsLength: settings.UnitsLength
                )
            ) {
                HStack {
                    Text("Elevation Projected Render")
                }
            }
            NavigationLink(
            destination: ElevationCrossSectionRender(
                scan: self.model.scan,
                color: meshColor,
                ambientColor: settings.ColorLightAmbient,
                quiltMesh: settings.ColorMeshQuilt,
                unitsLength: settings.UnitsLength
            )
            ) {
                HStack {
                    Text("Cross Section Render")
                }
            }
        }
    }
}

//#if DEBUG
//struct SavedScanDetailLinks_Previews: PreviewProvider {
//    static var previews: some View {
//        SavedScanDetailLinks()
//    }
//}
//#endif
