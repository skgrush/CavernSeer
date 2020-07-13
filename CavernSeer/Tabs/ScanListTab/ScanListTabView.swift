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

    var tab: Tabs = Tabs.ScanListTab
    var tabName = "Scan List"
    var tabImage: Image { Image(systemName: "list.dash") }

    func tabPanelView() -> ScanListTabView {
        ScanListTabView()
    }
}

struct ScanListTabView: View {

    @EnvironmentObject
    var scanStore: ScanStore

    @State
    private var editMode = EditMode.inactive

    @State
    private var showMergeTool = false

    var body: some View {
        GeometryReader {
            geometry in
            NavigationView {
                SavedScanListScrollView(
                    width: geometry.size.width,
                    height: geometry.size.height,
                    editMode: $editMode
                )
                .toolbar {
                    ToolbarItem(placement: .bottomBar) {
                        Button(
                            action: { self.deleteSelected() },
                            label: { Image(systemName: "trash") }
                        )
                        .disabled(self.scanStore.selection.isEmpty)
                    }
                }
                .environment(\.editMode, self.$editMode)
            }
        }
    }

    func deleteSelected() {
        let ids = scanStore.selection
        scanStore.selection.removeAll()

        scanStore.modelData
            .filter { ids.contains($0.id) }
            .forEach { self.scanStore.deleteFile(model: $0) }

        scanStore.update()
    }
}

#if DEBUG
struct ScanListTabView_Previews: PreviewProvider {
    static var previews: some View {
        ScanListTabView()
    }
}
#endif
