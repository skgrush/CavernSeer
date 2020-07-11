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

    var scanner = ScannerTab()
    var scanList = ScanListTab()
 
    var body: some View {
        TabView(selection: $selection){

            scanList.tabPanelView()
                .tabItem {
                    VStack {
                        scanList.tabImage
                        Text(scanList.tabName)
                    }
                }
                .tag(scanList.tab)

            scanner.tabPanelView()
                .tabItem {
                    VStack {
                        scanner.tabImage
                        Text(scanner.tabName)
                    }
                }
                .tag(scanner.tab)

        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
