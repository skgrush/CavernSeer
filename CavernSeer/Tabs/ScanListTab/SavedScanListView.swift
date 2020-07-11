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
        List(scanStore.modelData) {
            model
            in
            NavigationLink(destination: SavedScanDetail(model: model)) {
                SavedScanRow(model: model)
            }
        }
        .navigationTitle("Scan List")
    }
}

#if DEBUG
struct SavedScanListView_Previews: PreviewProvider {
    static var previews: some View {
        SavedScanListView()
    }
}
#endif
