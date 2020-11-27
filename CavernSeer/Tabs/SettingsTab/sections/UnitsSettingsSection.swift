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
                    ForEach(SettingsStore.lengthPrefs, id: \.self) {
                        Text($0.name).tag($0 as LengthPreference?)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }
        }
    }
}

#if DEBUG
struct UnitsSettingsSection_Previews: PreviewProvider {
    static var settings = SettingsStore()

    static var previews: some View {
        UnitsSettingsSection().environmentObject(settings)
    }
}
#endif
