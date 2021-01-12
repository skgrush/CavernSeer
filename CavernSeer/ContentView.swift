//
//  ContentView.swift
//  CavernSeer
//
//  Created by Samuel Grush on 6/27/20.
//  Copyright © 2020 Samuel K. Grush. All rights reserved.
//

import SwiftUI

fileprivate let supportedTabs: [TabProtocol] = [
    ProjectListTab(),
    ScanListTab(),
    ScannerTab(),
    SettingsTab(),
].filter({ $0.isSupported })

struct ContentView: View {
    @State private var selection: Tabs = Tabs.ScanListTab
    @EnvironmentObject var scanStore: ScanStore
    @EnvironmentObject var fileOpener: FileOpener

    let tabs: [TabProtocol] = supportedTabs
 
    var body: some View {
        TabView(selection: $selection){

            ForEach(tabs, id: \.tab) {
                tab in
                tab.getTabPanelView(selected: selection == tab.tab)
                    .tabItem {
                        VStack {
                            tab.tabImage
                            Text(tab.tabName)
                        }
                    }
            }
        }
        // TODO
        .sheet(isPresented: $fileOpener.showOpenResults) {
            if (fileOpener.openSuccesses?.count ?? 0 > 0 &&
                    fileOpener.openFailures?.count ?? 0 == 0
            ) {
                /// success-state view
                VStack {
                    Text("Successful import!")
                    List(Array(fileOpener.openSuccesses!.keys), id: \.self) {
                        url
                        in
                        Button(action: { openFile(url: url) }) {
                            Text(url.lastPathComponent)
                        }
                    }
                }
            } else if fileOpener.openFailures != nil {
                /// failure-state view
                VStack {
                    List(
                        Array((fileOpener.openSuccesses ?? [:]).keys),
                        id: \.self
                    ) {
                        url
                        in
                        Text("\(url.lastPathComponent): successful open")
                    }
                    List(Array(fileOpener.openFailures!.keys), id: \.self) {
                        url
                        in
                        Text("\(url.lastPathComponent): " +
                             (fileOpener.openFailures![url] ?? ""))
                    }
                }
            } else {
                VStack {
                    Text("Unknown issue opening files")
                }
            }
        }
    }


    private func openFile(url: URL) {
        self.fileOpener.showOpenResults = false
        let type = self.fileOpener.openSuccesses![url]!

        switch (type) {
            case .project:
                self.selection = .ProjectListTab
            case .scan:
                self.selection = .ScanListTab
                do {
                    try self.scanStore.update()
                } catch {
                    fatalError("Error updating: \(error.localizedDescription)")
                }
                self.scanStore.setVisible(visible: url)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
