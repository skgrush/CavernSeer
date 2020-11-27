//
//  Interaction3dSettingsSection.swift
//  CavernSeer
//
//  Created by Samuel Grush on 11/22/20.
//  Copyright © 2020 Samuel K. Grush. All rights reserved.
//

import SwiftUI
import SceneKit

struct Interaction3dSettingsSection: View {

    @EnvironmentObject
    var settings: SettingsStore

    private static let modes = SettingsStore.modes3d

    var body: some View {
        Group() {
            HStack {
                picker
            }
        }
    }

    private var picker: some View {
        Picker(
            SettingsKey.InteractionMode3d.name,
            selection: $settings.InteractionMode3d
        ) {
            ForEach(0..<Self.modes.count) {
                Text(Self.modes[$0].name)
                    .tag(Self.modes[$0] as SCNInteractionMode?)
            }
        }
    }
}

#if DEBUG
struct Interaction3dSettingsSection_Previews: PreviewProvider {
    static var settings = SettingsStore()

    static var previews: some View {
        Interaction3dSettingsSection().environmentObject(settings)
    }
}
#endif
