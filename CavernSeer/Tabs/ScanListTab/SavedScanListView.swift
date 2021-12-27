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

    @EnvironmentObject
    var settings: SettingsStore

    var listStyle: ListStyleT

    @State
    private var searchText = ""

    @State
    private var editMode: EditMode = .inactive

    @State
    private var showShare = false

    @State
    private var initialLoad = true

//    @State
//    private var showMergeTool = false

    var searchResults: [ScanCacheFile] {
        if searchText.isEmpty {
            return scanStore.caches
        } else {
            let term = searchText.lowercased()
            let results = scanStore.caches.filter {
                $0.searchableText.contains(term)
            }
            return results
        }
    }

    var body: some View {
        List(selection: $scanStore.selection) {
            ForEach(searchResults) {
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
        .searchable(text: $searchText, placement: .navigationBarDrawer)
        .refreshable {
            self.scanStore.update()
        }
        .environment(\.editMode, self.$editMode)
        .navigationTitle(Text("Scan List"))
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                editButton
                sortMenu
            }
            ToolbarItemGroup(placement: .bottomBar) {
                if editMode == .active {
                    Button(
                        action: { self.deleteSelected() },
                        label: { Image(systemName: "trash") }
                    )
                    .disabled(self.scanStore.selection.isEmpty)
                }
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
        .onAppear(perform: {
            // try not to update multiple times, especially at startup
            if self.initialLoad {
                self.initialLoad = false
                self.scanStore.update()
            }
        })
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

    private var sortMenu: some View {
        Menu {
            Picker(
                selection: $settings.SortingMethod,
                label: Image(systemName: SettingsKey.SortingMethod.name)
            ) {
                ForEach(SortMethod.allCases) {
                    method in
                    Text(method.name).tag(method)
                }
            }
            .pickerStyle(.inline)
                Picker(
                    selection: $settings.SortingOrder,
                    label: Text(SettingsKey.SortingOrder.name)
                ) {
                    Text("Ascending").tag(SortOrder.forward)
                    Text("Descending").tag(SortOrder.reverse)
                }
                .pickerStyle(.inline)
        } label: {
            Image(systemName: "arrow.up.arrow.down")
        }
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
}

//#if DEBUG
//struct SavedScanListView_Previews: PreviewProvider {
//    static var previews: some View {
//
//        SavedScanListView(editMode: Binding()
//    }
//}
//#endif
