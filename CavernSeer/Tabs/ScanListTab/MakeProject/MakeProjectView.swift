//
//  MakeProjectView.swift
//  CavernSeer
//
//  Created by Samuel Grush on 7/23/20.
//  Copyright © 2020 Samuel K. Grush. All rights reserved.
//

import SwiftUI

struct MakeProjectView: View {


    var projectStore: ProjectStore

    @ObservedObject
    var viewModel: MakeProjectModel

    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

struct MakeProjectView_Previews: PreviewProvider {
    static var previews: some View {
        let projStore = ProjectStore()
        let scanStore = ScanStore(settings: SettingsStore())

        return MakeProjectView(
            projectStore: projStore,
            viewModel: MakeProjectModel(store: scanStore,
                                        projectStore: projStore))
    }
}
