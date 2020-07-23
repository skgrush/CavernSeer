//
//  MergeTool.swift
//  CavernSeer
//
//  Created by Samuel Grush on 7/11/20.
//  Copyright © 2020 Samuel K. Grush. All rights reserved.
//

import SwiftUI


//final class MergeTool: UIViewController, UIViewRepresentable {
//
//    let store: ScanStore
//
//    init(store: ScanStore) {
//        self.store = store
//    }
//
//    required init?(coder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//
//
//}

struct MergeTool: View {

    var scanStore: ScanStore

    var selectedModels: [SavedScanModel] {
        self.scanStore.modelData.filter {
            scanStore.selection.contains($0.id)
        }
    }

    @State
    var currentStationSelect = [SurveyStation?]()

    /// array of station-select arrays
    @State
    var stationMerges = [[SurveyStation]]()

    private var currentStationSelectStrings: [String] {
        currentStationSelect.map {
            $0 == nil ? "nil" : $0!.identifier.uuidString
        }
    }

    var body: some View {
        VStack {
            HStack {
                VStack {
                    Text("Merges")
                }
                VStack {
                    Text("Current selection:")
                    List(currentStationSelectStrings, id: \.self) {
                        stationUuid in
                        Text(stationUuid)
                    }
                    Button(action: mergeThese) {
                        Text("Merge these")
                    }
                }
            }
            VStack { /// all of the selection views
                ForEach(0..<currentStationSelect.count) {
                    idx in
                    MergeToolModelRow(
                        model: selectedModels[idx],
                        selected: $currentStationSelect[idx]
                    )
                }
            }
        }
        .onAppear(perform: initStates)
    }

    func mergeThese() {
        let currentSelect = currentStationSelect
        
    }

    private func initStates() {
        resetCurrentSelection()
    }

    private func resetCurrentSelection() {
        currentStationSelect.removeAll()
        selectedModels.forEach { _ in currentStationSelect.append(nil) }
    }
}


struct MergeToolModelRow: View {
    var model: SavedScanModel

    @Binding
    var selected: SurveyStation?

    var body: some View {
        VStack {
            Text(model.id).font(.headline)
            HStack {
                List(model.scan.stations, id: \.identifier) {
                    station
                    in
                    Button(
                        action: {
                            if selected == station {
                                selected = nil
                            } else {
                                selected = station
                            }
                        }
                    ) { Text(station.identifier.uuidString) }
                    .listRowBackground(
                        selected == station ? Color.red : nil
                    )
                }
                ProjectedMiniWorldRender(
                    scan: model.scan,
                    selection: $selected
                )
            }
        }
    }
}


//final class MergeToolController: UIViewController, UIViewRepresentable {
//
//    let store: ScanStore
//
//    init(store: ScanStore) {
//        self.store = store
//    }
//
//    required init?(coder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//
//    func makeUIView(context: Context) -> some View {
//
//    }
//
//    func updateUIView(_ uiView: UIViewType, context: Context) {
//        <#code#>
//    }
//}


#if DEBUG
struct MergeTool_Previews: PreviewProvider {
    static var previews: some View {
        MergeTool(scanStore: ScanStore())
    }
}
#endif
