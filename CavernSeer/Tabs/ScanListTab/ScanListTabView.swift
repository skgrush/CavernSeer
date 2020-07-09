//
//  ScanListTabView.swift
//  CavernSeer
//
//  Created by Samuel Grush on 7/6/20.
//  Copyright © 2020 Samuel K. Grush. All rights reserved.
//

import SwiftUI

final class ScanListTab : TabProtocol {
    typealias ViewType = ScanListTabView

    var tabPanelView: ScanListTabView { ScanListTabView() }
    var tab: Tabs = Tabs.ScanListTab
    var tabName = "Scan List"
    var tabImage: Image { Image(systemName: "list.dash") }
}

struct ScanListTabView: View {

    @EnvironmentObject
    var scanStore: ScanStore

    var body: some View {
        GeometryReader {
            geometry in
            NavigationView {
                SavedScanListScrollView(
                    width: geometry.size.width,
                    height: geometry.size.height
                )
            }
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
