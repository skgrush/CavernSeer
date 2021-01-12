//
//  ProjectListTabView.swift
//  CavernSeer
//
//  Created by Samuel Grush on 7/22/20.
//  Copyright © 2020 Samuel K. Grush. All rights reserved.
//

import SwiftUI

final class ProjectListTab : TabProtocol {
    /// `false` as this is incomplete
    let isSupported: Bool = false

    var tab = Tabs.ProjectListTab
    var tabName = "Project List"
    var tabImage: Image { Image(systemName: "list.bullet.indent") }

    func getTabPanelView(selected: Bool) -> AnyView {
        AnyView(ProjectListTabView())
    }
}

struct ProjectListTabView: View {
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

struct ProjectListTabView_Previews: PreviewProvider {
    static var previews: some View {
        ProjectListTabView()
    }
}
