//
//  ScanListTabView.swift
//  CavernSeer
//
//  Created by Samuel Grush on 7/6/20.
//  Copyright © 2020 Samuel K. Grush. All rights reserved.
//

import SwiftUI /// View, Image

final class ScanListTab : TabProtocol {

    let isSupported = true

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
            SavedScanListView(listStyle: .sidebar)
        }
    }
}

#if DEBUG
struct ScanListTabView_Previews: PreviewProvider {

    private static let scanStore = setupScanStore()

    static var previews: some View {
        Group {
            ScanListTabView()
                .previewDevice(PreviewDevice(rawValue: "iPhone 12 Pro"))
                .environment(\.colorScheme, .dark)

            ScanListTabView()
                .previewDevice(PreviewDevice(rawValue: "iPad Pro (12.9-inch) (5th generation)"))
                .environment(\.colorScheme, .light)

            ScanListTabView()
                .previewDevice(PreviewDevice(rawValue: "iPhone 8 Plus"))
                .environment(\.colorScheme, .light)

        }.environmentObject(scanStore)
    }

    private static func setupScanStore() -> ScanStore {
        let store = ScanStore(settings: SettingsStore())

        store.modelDataInMemory = dummySavedScans
        store.caches = dummyScanCaches

        return store
    }
}
#endif
