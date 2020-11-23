//
//  UnitsSettingsSection.swift
//  CavernSeer
//
//  Created by Samuel Grush on 11/22/20.
//  Copyright © 2020 Samuel K. Grush. All rights reserved.
//

import SwiftUI

struct UnitsSettingsSection: View {
    @EnvironmentObject
    var settings: SettingsStore

    var body: some View {
        Group() {
            HStack {
                Picker(
                    SettingsKey.UnitsLength.name,
                    selection: $settings.UnitsLength
                ) {
                    ForEach(0..<SettingsStore.lengthPrefs.count) {
                        Text(SettingsStore.lengthPrefs[$0].name)
                            .tag(SettingsStore.lengthPrefs[$0])
                    }
                }
            }
        }
    }
}

struct UnitsSettingsSection_Previews: PreviewProvider {
    static var settings = SettingsStore()

    static var previews: some View {
        UnitsSettingsSection().environmentObject(settings)
    }
}
