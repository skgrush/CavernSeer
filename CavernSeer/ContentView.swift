//
//  ContentView.swift
//  CavernSeer
//
//  Created by Samuel Grush on 6/27/20.
//  Copyright © 2020 Samuel K. Grush. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    @State private var selection: Tabs = Tabs.ScanListTab

    let tabs: [TabProtocol] = [
        ProjectListTab(),
        ScanListTab(),
        ScannerTab()
    ]
 
    var body: some View {
        TabView(selection: $selection){

            ForEach(tabs, id: \.tab) {
                tab in
                tab.tabPanelView
                    .tabItem {
                        VStack {
                            tab.tabImage
                            Text(tab.tabName)
                        }
                    }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
