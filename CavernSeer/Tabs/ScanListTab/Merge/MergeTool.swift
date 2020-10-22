//
//  MergeTool.swift
//  CavernSeer
//
//  Created by Samuel Grush on 7/11/20.
//  Copyright © 2020 Samuel K. Grush. All rights reserved.
//

import SwiftUI

// TODO: Merge Tool
//struct MergeTool: View {
//
//    var scanStore: ScanStore
//
//    @ObservedObject
//    var viewModel: MergeToolModel
//
//    @State
//    var showAnalyzer: Bool = false

//    var body: some View {
//        VStack {
//            HStack {
//                VStack {
//                    Text("Merges").font(.headline)
//                    ForEach(viewModel.stationGroups) {
//                        group in
//                        GroupBox(label: Text(group.name)) {
//                            ForEach(
//                                Array(group.stations),
//                                id: \.0
//                            ) {
//                                (key, station) in
//                                Text("\(key): \(station.name)")
//                            }
//                        }
//                    }
//                    Button(action: { showAnalyzer = true }) {
//                        Text("Analyzer merge")
//                    }
//                }
//                Divider()
//                VStack {
//                    Text("Current selection:").font(.headline)
//                    List(
//                        Array(viewModel.currentlySelectedStations),
//                        id: \.0
//                    ) {
//                        (key, station) in
//                        Text("\(key): \(station.name)")
//                    }
//                    TextField(
//                        "New station name",
//                        text: $viewModel.currentSelectionName
//                    )
//                    Button(action: viewModel.mergeSelections) {
//                        Text("Merge")
//                    }.disabled(mergeDisabled)
//                }
//            }
//            Divider()
//            VStack { /// all of the selection views
//                ForEach(
//                    Array(viewModel.selectedModels.keys),
//                    id: \.self
//                ){
//                    id in
//                    MergeToolModelRow(
//                        viewModel: viewModel,
//                        modelId: id
//                    )
//                }
//            }
//        }
//        .sheet(isPresented: $showAnalyzer) {
//            MergeAnalyzer(viewModel: viewModel)
//        }
//    }
//
//    var mergeDisabled: Bool {
//        let newName = viewModel.currentSelectionName
//        return
//            newName.count == 0 ||
//            viewModel.currentlySelectedStations.count == 0 ||
//            viewModel.stationGroupNames.contains(newName)
//    }
//}
//
//
//struct MergeToolModelRow: View {
//
//    @ObservedObject
//    var viewModel: MergeToolModel
//
//    var modelId: MergeToolModel.ModelId
//
//    var model: SavedScanModel {
//        viewModel.selectedModels[modelId]!
//    }
//
//    var selected: SurveyStation? {
//        viewModel.currentlySelectedStations[modelId]
//    }
//
//    var body: some View {
//        GroupBox(label: Text(model.id)) {
//            HStack {
//                List(model.scan.stations, id: \.identifier) {
//                    station
//                    in
//                    Button(action: { select(station: station) }) {
//                        Text(station.name)
//                    }
//                    .background(
//                        selected == station ? Color.red : nil
//                    )
//                }
//                ProjectedMiniWorldRender(
//                    scan: model.scan,
//                    selection: $viewModel.currentlySelectedStations[modelId]
//                )
//            }
//        }
//    }
//
//    func select(station: SurveyStation?) {
////        viewModel.objectWillChange.send()
//        viewModel.select(station: station, from: model)
//    }
//}
//
//
//#if DEBUG
//struct MergeTool_Previews: PreviewProvider {
//    static var previews: some View {
//        let store = ScanStore()
//        return MergeTool(
//            scanStore: store,
//            viewModel: MergeToolModel(store: store)
//        )
//    }
//}
//#endif
