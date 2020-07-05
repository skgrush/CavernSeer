//
//  ContentView.swift
//  CavernSeer
//
//  Created by Samuel Grush on 6/27/20.
//  Copyright © 2020 Samuel K. Grush. All rights reserved.
//

import SwiftUI


struct ContentView: View {
    @State private var selection: Tabs = Tabs.ScanTab

    var scanner = ScannerTab()
 
    var body: some View {
        TabView(selection: $selection){
            scanner.tabPanelView
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
