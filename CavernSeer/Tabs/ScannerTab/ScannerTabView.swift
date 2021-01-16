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

    var isSelected: Bool

    @EnvironmentObject
    private var scanStore: ScanStore

    @ObservedObject
    private var scanModel = ScannerModel()

    var body: some View {
        ZStack(alignment: .bottom) {
            if isSelected {
                ARViewScannerContainer(scanModel: scanModel)
                    .edgesIgnoringSafeArea(.all)
            }

            controls
                .background(
                    Color(UIColor.systemGray6).opacity(0.4).ignoresSafeArea()
                )
        }
    }

    private var controls: some View {
        VStack {
            HStack {
                Text(scanModel.message)
            }

            // controls
            HStack {
                debugButtons.frame(width: 100)

                Spacer()

                if scanModel.scanEnabled {
                    saveOrCancel
                } else {
                    captureButton
                }

                Spacer()

                flashButton.frame(width: 100)
            }
            .padding(10)
        }
    }

    private var captureButton: some View {

        let color: Color = .primary

        /// the standard start-capture button
        return Button(
            action: { self.scanModel.scanEnabled = true },
            label: {
                Circle()
                    .foregroundColor(color)
                    .frame(width: 70, height: 70, alignment: .center)
                    .overlay(
                        Circle()
                            .stroke(color, lineWidth: 2)
                            .frame(width: 80, height: 80, alignment: .center)
                    )
            }
        )

    }

    private var saveOrCancel: some View {
        ZStack(alignment: .topTrailing) {
            /// save-capture button
            Button(
                action: { self.scanModel.saveScan(scanStore: self.scanStore) },
                label: {
                    Circle()
                        .foregroundColor(.secondary)
                        .frame(width: 70, height: 70, alignment: .center)
                }
            )
            /// cancel button
            Button(
                action: { self.scanModel.scanEnabled = false },
                label: {
                    Circle()
                        .frame(width: 20, height: 20, alignment: .center)
                        .overlay(
                            Image(systemName: "trash")
                                .font(.system(size: 20, weight: .medium, design: .default))
                                .foregroundColor(.red)
                        )
                }
            )
        }
    }

    private var flashButton: some View {
        let enabled = self.scanModel.torchEnabled

        return Button(
            action: { self.scanModel.torchEnabled = !enabled },
            label: {
                Image(systemName: enabled ? "bolt.fill" : "bolt.slash.fill")
                    .font(.system(size: 20, weight: .medium, design: .default))
            }
        )
        .accentColor(enabled ? .yellow : .white)
    }

    private var debugButtons: some View {
        let debug = self.scanModel.showDebug
        let mesh = self.scanModel.meshEnabled

        return VStack {
            Button(
                action: { self.scanModel.showDebug = !debug },
                label: { Text("Debug").accentColor(debug ? .primary : .secondary) }
            )
            .padding(.bottom, 5)
            Button(
                action: { self.scanModel.meshEnabled = !mesh },
                label: { Text("Mesh").accentColor(mesh ? .primary : .secondary) }
            )
        }
    }
}


#if DEBUG

struct ScannerTabView_Previews: PreviewProvider {

    private static let store = ScanStore()

    private static let tab = ScannerTab()

    static var previews: some View {
        Group {
            view
                .previewDevice(PreviewDevice(rawValue: "iPhone 12 Pro"))
                .environment(\.colorScheme, .dark)

            view
                .previewDevice(PreviewDevice(rawValue: "iPad Pro (11-inch)"))
                .environment(\.colorScheme, .light)

        }.environmentObject(store)
    }

    private static var view: some View {
        TabView {
            tab.getTabPanelView(selected: true)
                .tabItem {
                    VStack {
                        tab.tabImage
                        Text(tab.tabName)
                    }
                }
        }
    }
}

#endif
