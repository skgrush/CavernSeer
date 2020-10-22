//
//  MergeToolModel.swift
//  CavernSeer
//
//  Created by Samuel Grush on 7/12/20.
//  Copyright © 2020 Samuel K. Grush. All rights reserved.
//

import Foundation

// TODO: Merge Tool
//class MergeToolModel : ObservableObject {
//
//    typealias ModelId = String
//
//    let store: ScanStore
//
//    /// The models of the scans to be merged
//    @Published
//    var selectedModels = [ModelId: SavedScanModel]() // [SavedScanModel]
//
//    /// Mapping of model ids to their selected survey station
//    @Published
//    var currentlySelectedStations = [ModelId: SurveyStation]()
//
//    @Published
//    var currentSelectionName = ""
//
//    @Published
//    var newScanName = ""
//
//    /// Array of *planned* sets of stations  to merge
//    @Published
//    var stationGroups = [StationGroup]()
//
//    @Published
//    var rootModel: ModelId? {
//        didSet {
//            renderSequence.removeAll()
//            stationGroupSequence.removeAll()
//            if rootModel != nil {
//                renderSequence.append(rootModel!)
//            }
//        }
//    }
//
//    @Published
//    var renderSequence: [ModelId] = []
//
//    @Published
//    var stationGroupSequence = [StationGroup]()
//
//    @Published
//    var demoScanFile: ScanFile?
//
//    var stationGroupNames: [String] {
//        stationGroups.map { $0.name }
//    }
//
//    var unsequencedStationGroups: [StationGroup] {
//        var groups = Set(self.stationGroups)
//        groups.subtract(self.stationGroupSequence)
//        return Array(groups)
//    }
//
//    var unsequencedModels: [ModelId] {
//        var models = Set(self.selectedModels.keys)
//        models.subtract(self.renderSequence)
//        return Array(models)
//    }
//
//    convenience init(store: ScanStore) {
//        self.init(
//            selectedModels: store.modelData.filter {
//                store.selection.contains($0.id)
//            },
//            store: store
//        )
//    }
//
//    init(selectedModels: [SavedScanModel], store: ScanStore) {
//        self.store = store
//        for model in selectedModels {
//            self.selectedModels[model.id] = model
//        }
//    }
//
//    func select(station: SurveyStation?, from: SavedScanModel) {
//        let currentValue = currentlySelectedStations[from.id]
//
//        currentlySelectedStations[from.id]
//            = currentValue == station
//                ? nil
//                : station
//    }
//
//    func mergeSelections() {
//        let newMerge = StationGroup(
//            name: currentSelectionName,
//            stations: currentlySelectedStations
//        )
//        stationGroups.append(newMerge)
//
//        currentSelectionName = ""
//        currentlySelectedStations.removeAll()
//    }
//}
//
//
//extension MergeToolModel {
//    struct StationGroup : Identifiable, Hashable {
//        var id: String { name }
//
//        var name: String
//        var stations: [ModelId: SurveyStation]
//
//        var rootModel: ModelId?
//    }
//}
