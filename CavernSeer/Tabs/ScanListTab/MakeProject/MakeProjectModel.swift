//
//  MakeProjectModel.swift
//  CavernSeer
//
//  Created by Samuel Grush on 7/23/20.
//  Copyright © 2020 Samuel K. Grush. All rights reserved.
//

import Foundation

class MakeProjectModel : ObservableObject {

    typealias ModelId = String

    let scanStore: ScanStore
    let projStore: ProjectStore

    /// The models selected from the ScanList that can be combined from
    @Published
    var modelPool: [ModelId: SavedScanModel]

    /// Survey stations that are currently selected that the user wants to combine
    @Published
    var currentlySelectedStations = [ModelId: SurveyStation]()

    /// name to be given to the currently selected stations when combined
    @Published
    var currentSelectioName = ""

    /// name of the project to be created
    @Published
    var newProjectName = ""

    /// Array of *all planned* sets of stations  to merge
    @Published
    var stationGroups = [StationGroup]()

    @Published
    var rootModel: ModelId?

    @Published
    var renderSequence = [ModelId]()

    @Published
    var stationGroupSequence = [StationGroup.Id]()

    var allStationGroupIds: [StationGroup.Id] {
        stationGroups.map { $0.id }
    }

    var unsequencedStationGroups: [StationGroup.Id] {
        var groups = Set(self.allStationGroupIds)
        groups.subtract(self.stationGroupSequence)
        return Array(groups)
    }

    var unsequencedModels: [ModelId] {
        var models = Set(self.modelPool.keys)
        models.subtract(self.renderSequence)
        return Array(models)
    }

    convenience init(store: ScanStore, projectStore: ProjectStore) {
        self.init(
            modelPool: store.getSelectionModels(),
            store,
            projectStore
        )
    }

    init(modelPool: [SavedScanModel], _ scanStore: ScanStore, _ projStore: ProjectStore) {
        self.scanStore = scanStore
        self.projStore = projStore
        self.modelPool = Dictionary(uniqueKeysWithValues:
                                        modelPool.lazy.map { ($0.id, $0) })
    }

    func groupSelections() {
        let newGroup = StationGroup(name: currentSelectioName, stations: currentlySelectedStations)
        stationGroups.append(newGroup)

        currentSelectioName = ""
        currentlySelectedStations.removeAll()
    }

    
}


extension MakeProjectModel {
    struct StationGroup : Identifiable, Hashable {
        typealias Id = String

        var id: Id { name }
        /// the name of the new combined station
        var name: String
        /// maps the ID of the `SavedScanModel` of the corresponding `SurveyStation`
        var stations: [ModelId: SurveyStation]

        /// the model that all these stations are positioned relative to
        var rootModel: ModelId?
    }
}
