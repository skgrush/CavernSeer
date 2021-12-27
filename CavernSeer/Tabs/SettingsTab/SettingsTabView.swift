//
//  SettingsTabView.swift
//  CavernSeer
//
//  Created by Samuel Grush on 11/15/20.
//  Copyright © 2021 Samuel K. Grush. All rights reserved.
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

enum SettingsPage {
    case preferences
    case advanced
}

struct SettingsTabView: View {

    @EnvironmentObject
    var settings: SettingsStore

    var isSelected: Bool

    @State
    var selection: SettingsPage? = .preferences

    var body: some View {
        NavigationView {
            List {
                NavigationLink(
                    tag: SettingsPage.preferences,
                    selection: $selection,
                    destination: {
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
                        }
                    }
                ) {
                    HStack { Text("Preferences") }
                }

                NavigationLink(
                    tag: SettingsPage.advanced,
                    selection: $selection,
                    destination: {
                        Form {
                            Section(header: Text("Files")) {
                                FileSettingsSection()
                            }

                            Section(header: Text("Debug")) {
                                DebugSection()
                            }
                        }
                    }
                ) {
                    Text("Advanced")
                }
            }
        }
        .navigationViewStyle(.automatic)
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
