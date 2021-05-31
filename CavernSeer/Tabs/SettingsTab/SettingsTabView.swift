//
//  SettingsTabView.swift
//  CavernSeer
//
//  Created by Samuel Grush on 11/15/20.
//  Copyright © 2020 Samuel K. Grush. All rights reserved.
//

import SwiftUI

final class SettingsTab : TabProtocol {
    let isSupported: Bool = true
    
    var tab: Tabs = .SettingsTab
    var tabName = "Settings"
    var tabImage: Image { Image(systemName: "gear") }

    func getTabPanelView(selected: Bool) -> AnyView {
        AnyView(SettingsTabView(isSelected: selected))
    }
}

struct SettingsTabView: View {

    @EnvironmentObject
    var settings: SettingsStore

    var isSelected: Bool

    var body: some View {
        NavigationView {
            Form {

                /// colors
                Section(header: Text("Color")) {
                    ColorsSettingsSection()
                }

                /// units
                Section(header: Text("Units")) {
                    UnitsSettingsSection()
                }

                /// 3D interaction mode
                Section {
                    Interaction3dSettingsSection()
                }

                Section(header: Text("Files")) {
                    FileSettingsSection()
                }
            }
        }
    }
}

#if DEBUG
struct SettingsTabView_Previews: PreviewProvider {
    static var settings = SettingsStore()

    static var previews: some View {
        SettingsTabView(isSelected: false).environmentObject(settings)
    }
}
#endif
