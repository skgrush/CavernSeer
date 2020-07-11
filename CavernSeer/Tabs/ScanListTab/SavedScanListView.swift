//
//  SavedScanList.swift
//  CavernSeer
//
//  Created by Samuel Grush on 7/6/20.
//  Copyright © 2020 Samuel K. Grush. All rights reserved.
//

import SwiftUI

struct SavedScanListView: View {

    @EnvironmentObject
    var scanStore: ScanStore

    @State
    private var selection: URL? = nil
    @State
    private var showShare = false

    var body: some View {
        List {
            ForEach(scanStore.modelData) {
                model
                in
                NavigationLink(destination: SavedScanDetail(model: model)) {
                    SavedScanRow(model: model)
                }
            }
            .onDelete(perform: delete)
        }
        .navigationTitle("Scan List")
        .navigationBarItems(trailing: EditButton())
    }

    func delete(at offset: IndexSet) {
        let modelData = scanStore.modelData
        offset
            .map { modelData[$0] }
            .forEach { self.scanStore.deleteFile(model: $0) }
    }
}

#if DEBUG
struct SavedScanListView_Previews: PreviewProvider {
    static var previews: some View {
        SavedScanListView()
    }
}
#endif
