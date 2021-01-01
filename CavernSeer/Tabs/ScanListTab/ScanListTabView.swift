//
//  ScanListTabView.swift
//  CavernSeer
//
//  Created by Samuel Grush on 7/6/20.
//  Copyright © 2020 Samuel K. Grush. All rights reserved.
//

import SwiftUI /// View, Image

final class ScanListTab : TabProtocol {

    var tab: Tabs = Tabs.ScanListTab
    var tabName = "Scan List"
    var tabImage: Image { Image(systemName: "list.dash") }

    func getTabPanelView(selected: Bool) -> AnyView {
        AnyView(ScanListTabView())
    }
}

struct ScanListTabView: View {

    @EnvironmentObject
    var scanStore: ScanStore

    @State
    private var editMode = EditMode.inactive

    var body: some View {
        NavigationView {
            SavedScanListView(listStyle: SidebarListStyle())
        }
    }
}

#if DEBUG
struct ScanListTabView_Previews: PreviewProvider {
    static var previews: some View {
        ScanListTabView()
    }
}
#endif
