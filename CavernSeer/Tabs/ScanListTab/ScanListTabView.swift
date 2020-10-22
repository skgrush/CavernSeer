//
//  ScanListTabView.swift
//  CavernSeer
//
//  Created by Samuel Grush on 7/6/20.
//  Copyright © 2020 Samuel K. Grush. All rights reserved.
//

import SwiftUI

final class ScanListTab : TabProtocol {

    var tab: Tabs = Tabs.ScanListTab
    var tabName = "Scan List"
    var tabImage: Image { Image(systemName: "list.dash") }

    var tabPanelView: AnyView {
        AnyView(ScanListTabView())
    }
}

struct ScanListTabView: View {

    @EnvironmentObject
    var scanStore: ScanStore

    @State
    private var editMode = EditMode.inactive

//    @State
//    private var showMergeTool = false

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

// TODO: Merge Tool
//                    ToolbarItem(placement: .bottomBar) {
//                        Button(
//                            action: { self.showMergeTool = true },
//                            label: {
//                                HStack {
//                                    Spacer()
//                                    Text("Merge")
//                                    Image(systemName: "arrow.merge")
//                                }
//                            }
//                        )
//                        .disabled(self.scanStore.selection.isEmpty)
//                    }
                }
                .environment(\.editMode, self.$editMode)
            }
//            .sheet(isPresented: $showMergeTool) {
//                MergeTool(
//                    scanStore: scanStore,
//                    viewModel: MergeToolModel(store: scanStore)
//                )
//            }
        }
    }

    func deleteSelected() {
        let ids = scanStore.selection
        scanStore.selection.removeAll()

        scanStore.modelData
            .filter { ids.contains($0.id) }
            .forEach { self.scanStore.deleteFile(model: $0) }

        do {
            try scanStore.update()
        } catch {
            fatalError("Deletion failed: \(error.localizedDescription)")
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
