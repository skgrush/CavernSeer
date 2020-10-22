//
//  MergeAnalyzer.swift
//  CavernSeer
//
//  Created by Samuel Grush on 7/12/20.
//  Copyright © 2020 Samuel K. Grush. All rights reserved.
//

import SwiftUI

// TODO: Merge Tool
//struct MergeAnalyzer: View {
//    @ObservedObject
//    var viewModel: MergeToolModel
//
//
//
//    var body: some View {
//        VStack {
//            Picker(
//                selection: $viewModel.rootModel,
//                label: Text("Select root scan")
//            ) {
//                Text("--").tag(nil as MergeToolModel.ModelId?)
//                ForEach(Array(viewModel.selectedModels.keys), id: \.self) {
//                    Text($0).tag($0 as MergeToolModel.ModelId?)
//                }
//            }
//            HStack {
//                GroupBox(label: Text("sequenced scans")) {
//                    List(viewModel.renderSequence, id: \.self) {
//                        modelId in Text(modelId)
//                    }.disabled(true)
//                }
//                GroupBox(label: Text("unsequenced scans")) {
//                    List(viewModel.unsequencedModels, id: \.self) {
//                        modelId in Text(modelId)
//                    }.disabled(true)
//                }
//            }
//
//            Divider()
//
//            HStack {
//                GroupBox(label: Text("sequenced groups")) {
//                    List(viewModel.stationGroupSequence) {
//                        group in Text(group.id)
//                    }.disabled(true)
//                }
//                GroupBox(label: Text("unsequenced groups")) {
//                    List(viewModel.unsequencedStationGroups) {
//                        group in Text(group.id)
//                    }.disabled(true)
//                }
//            }
//
//            Divider()
//
//            viewModel.demoScanFile
//                .map { MiniWorldRender(scan: $0) }
//
//        }
//
//
//    }
//}

//struct MergeAnalyzer_Previews: PreviewProvider {
//    static var previews: some View {
//        MergeAnalyzer()
//    }
//}
