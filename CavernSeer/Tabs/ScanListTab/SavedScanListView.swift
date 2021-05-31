//
//  SavedScanList.swift
//  CavernSeer
//
//  Created by Samuel Grush on 7/6/20.
//  Copyright © 2020 Samuel K. Grush. All rights reserved.
//

import SwiftUI /// View

struct SavedScanListView<ListStyleT: ListStyle>: View {

    @EnvironmentObject
    var scanStore: ScanStore

    var listStyle: ListStyleT

    @State
    private var editMode: EditMode = .inactive

    @State
    private var showShare = false

//    @State
//    private var showMergeTool = false

    var body: some View {
        List(selection: $scanStore.selection) {
            ForEach(scanStore.caches) {
                cache
                in
                NavigationLink(
                    destination: SavedScanDetail(cache: cache),
                    tag: cache.id,
                    selection: $scanStore.visibleScan
                ) {
                    SavedScanRow(cache: cache)
                }
            }
            .onDelete(perform: delete)
        }
        .environment(\.editMode, self.$editMode)
        .navigationTitle("Scan List")
        .navigationBarItems(
            trailing: HStack {
                Button(
                    action: { self.refresh() },
                    label: { Image(systemName: "arrow.clockwise") }
                )
                editButton
            }
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
//            ToolbarItem(placement: .bottomBar) {
//                Button(
//                    action: { self.showMergeTool = true },
//                    label: {
//                        HStack {
//                            Spacer()
//                            Text("Merge")
//                            Image(systemName: "arrow.merge")
//                        }
//                    }
//                )
//                .disabled(self.scanStore.selection.isEmpty)
//            }
        }
//        .sheet(isPresented: $showMergeTool) {
//            MergeTool(
//                scanStore: scanStore,
//                viewModel: MergeToolModel(store: scanStore)
//            )
//        }
        // TODO: uncomment to auto-load, see Issue #26
        //.onAppear(perform: self.refresh)
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

    private func deleteSelected() {
        let ids = self.scanStore.selection
        let caches = self.scanStore.caches
        let offsets = IndexSet(
            caches
            .indices
            .filter { idx in ids.contains(caches[idx].id) }
        )

        self.delete(at: offsets)
    }

    private func delete(at offset: IndexSet) {
        let caches = self.scanStore.caches

        offset
            .map { caches[$0] }
            .forEach { self.scanStore.deleteFile(id: $0.id) }
    }

    private func refresh() {
        do {
            try self.scanStore.update()
        } catch {
            fatalError("Update failed: \(error.localizedDescription)")
        }
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
