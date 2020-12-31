//
//  SavedScanList.swift
//  CavernSeer
//
//  Created by Samuel Grush on 7/6/20.
//  Copyright © 2020 Samuel K. Grush. All rights reserved.
//

import SwiftUI /// View

struct SavedScanListView: View {

    @EnvironmentObject
    var scanStore: ScanStore

    @Binding
    var editMode: EditMode

    @State
    private var showShare = false

    var body: some View {
        List(selection: $scanStore.selection) {
            ForEach(scanStore.previews) {
                preview
                in
                NavigationLink(
                    destination: SavedScanDetail(url: preview.url),
                    tag: preview.id,
                    selection: $scanStore.visibleScan
                ) {
                    SavedScanRow(preview: preview)
                }
            }
            .onDelete(perform: delete)
        }
        .environment(\.editMode, self.$editMode)
        .navigationTitle("Scan List")
        .navigationBarItems(trailing: editButton)
    }

    private var editButton: some View {
        let newMode: EditMode = self.editMode == .inactive ? .active : .inactive
        return Button(action: {
            self.scanStore.selection.removeAll()
            self.editMode = newMode
        }, label: {
            Text(
                newMode == .inactive
                    ? "Done"
                    : "Edit"
            )
        })
    }

    func delete(at offset: IndexSet) {
        let previews = self.scanStore.previews

        offset
            .map { previews[$0] }
            .forEach { self.scanStore.deleteFile(id: $0.id) }
    }
}

//#if DEBUG
//struct SavedScanListView_Previews: PreviewProvider {
//    static var previews: some View {
//
//        SavedScanListView(editMode: Binding()
//    }
//}
//#endif
