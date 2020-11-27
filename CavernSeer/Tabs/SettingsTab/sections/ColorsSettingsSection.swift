//
//  ColorsSettingsSection.swift
//  CavernSeer
//
//  Created by Samuel Grush on 11/22/20.
//  Copyright © 2020 Samuel K. Grush. All rights reserved.
//

import SwiftUI

struct ColorsSettingsSection: View {
    @EnvironmentObject
    var settings: SettingsStore

    var body: some View {
        Group() {
            HStack {
                ColorPicker(
                    SettingsKey.ColorMesh.name,
                    selection: $settings.ColorMesh,
                    supportsOpacity: true
                )
            }
        }

        Group() {
            HStack {
                Toggle(
                    SettingsKey.ColorMeshQuilt.name,
                    isOn: $settings.ColorMeshQuilt
                )
            }
        }

        Group() {
            HStack {
                ColorPicker(
                    SettingsKey.ColorLightAmbient.name,
                    selection: $settings.ColorLightAmbient,
                    supportsOpacity: true
                )
            }
        }
    }
}

#if DEBUG
struct ColorsSettingsSection_Previews: PreviewProvider {
    static var settings = SettingsStore()

    static var previews: some View {
        ColorsSettingsSection().environmentObject(settings)
    }
}
#endif
