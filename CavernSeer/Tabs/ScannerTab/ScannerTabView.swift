//
//  ScannerTabView.swift
//  CavernSeer
//
//  Created by Samuel Grush on 6/27/20.
//  Copyright © 2020 Samuel K. Grush. All rights reserved.
//

import SwiftUI /// AnyView, View, Image, EnvironmentObject

final class ScannerTab : TabProtocol {
    var isSupported: Bool { ScannerModel.supportsScan }

    var tab: Tabs = Tabs.ScanTab
    var tabName = "Scanner"
    var tabImage: Image { Image(systemName: "camera.viewfinder") }

    func getTabPanelView(selected: Bool) -> AnyView {
        AnyView(ScannerTabView(isSelected: selected))
    }
}

struct ScannerTabView: View {

    @EnvironmentObject
    var scanStore: ScanStore

    @ObservedObject
    var scanModel = ScannerModel()

    var isSelected: Bool

    var body: some View {
        VStack {

            if isSelected {
                ARViewScannerContainer(scanModel: scanModel)
                    .edgesIgnoringSafeArea(.all)
            }

            HStack {
                HStack {
                    Button(action: {
                        self.scanModel.scanEnabled = true
                    }) {
                        Text("Start Scan")
                    }.disabled(scanModel.scanEnabled)

                    Button(action: {
                        self.scanModel.scanEnabled = false
                    }) {
                        Text("Cancel Scan")
                    }.disabled(!scanModel.scanEnabled)

                    Button(action: {
                        self.scanModel.saveScan(scanStore: self.scanStore)
                    }) {
                        Text("Save")
                    }.disabled(!scanModel.scanEnabled)
                }

                HStack {
                    Toggle("Debug", isOn: $scanModel.showDebug)
                        .frame(maxWidth: 100)
                }

                Spacer()

                HStack {
                    Text(scanModel.message)
                }
            }
        }
    }
}
