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

    private let controlFrameHeight: CGFloat = 80

    var isSelected: Bool

    @EnvironmentObject
    private var scanStore: ScanStore

    @Environment(\.fakeScan)
    private var fakeScan: Bool

    @ObservedObject
    private var control = ScannerControlModel()

    var body: some View {
        if isSelected && control.cameraEnabled != false {
            if control.renderingPassiveView {
                ZStack(alignment: .bottom) {
                    PassiveCameraViewContainer(control: control)
                        .edgesIgnoringSafeArea(.all)
                    passiveControls.background(controlBackground)
                }
            } else if control.renderingARView {
                Spacer().fullScreenCover(
                    isPresented: $control.fullscreenPresented
                ) {
                    ZStack(alignment: .bottom) {
                        ActiveARViewContainer(control: control)
                            .edgesIgnoringSafeArea(.all)
                        activeControls.background(controlBackground)
                    }
                }
            }
        } else {
            Spacer()
        }
    }

    private var scanEnabled: Bool {
        return self.control.scanEnabled || self.fakeScan
    }

    // MARK: - Control views

    private let controlPadding = EdgeInsets(top: 5, leading: 10, bottom: 20, trailing: 10)

    private var controlBackground: some View {
        Color(UIColor.systemGray6).opacity(0.4).ignoresSafeArea()
    }

    private var activeControls: some View {
        VStack {
            messageView

            // controls
            HStack(alignment: .bottom) {
                debugButtons.frame(width: 100, height: controlFrameHeight)
                Spacer()
                saveOrCancel
                Spacer()
                flashButton.frame(width: 100, height: controlFrameHeight)
            }
            .padding(controlPadding)
        }
    }

    private var passiveControls: some View {
        VStack {
            messageView

            // controls
            HStack(alignment: .bottom) {
                Spacer().frame(width: 100, height: controlFrameHeight)
                Spacer()
                captureButton.frame(height: controlFrameHeight)
                Spacer()
                CompassView().frame(width: 100, height: controlFrameHeight)
            }
            .padding(controlPadding)
        }
    }

    private var messageView: some View {
        HStack {
            if !self.control.message.isEmpty {
                Text(self.control.message)
            }
        }
    }

    private var captureButton: some View {

        let color: Color = .primary

        /// the standard start-capture button
        return Button(
            action: { self.control.startScan() },
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
        VStack(alignment: .center) {
            /// cancel button
            Button(
                action: { self.control.cancelScan() },
                label: {
                    Text("Cancel Scan")
                        .foregroundColor(.red)
                        .padding(5)
                }
            )

            /// save-capture button
            Button(
                action: { self.control.saveScan(scanStore: self.scanStore) },
                label: {
                    Circle()
                        .foregroundColor(.secondary)
                        .frame(width: 70, height: 70, alignment: .center)
                }
            )
        }
    }

    private var flashButton: some View {
        let enabled = self.control.torchEnabled

        return Button(
            action: { self.control.toggleTorch(!enabled) },
            label: {
                Image(systemName: enabled ? "bolt.fill" : "bolt.slash.fill")
                    .font(.system(size: 20, weight: .medium, design: .default))
                    .padding(10)
            }
        )
        .accentColor(enabled ? .yellow : .primary)
    }

    private var debugButtons: some View {
        let debug = self.control.debugEnabled
        let mesh = self.control.meshEnabled

        return VStack {
            Button(
                action: { self.control.toggleDebug(!debug) },
                label: { Text("Debug").accentColor(debug ? .primary : .secondary) }
            )
            .padding(.bottom, 5)
            Button(
                action: { self.control.toggleMesh(!mesh) },
                label: { Text("Mesh").accentColor(mesh ? .primary : .secondary) }
            )
        }
    }
}


#if DEBUG

struct ScannerTabView_Previews: PreviewProvider {
    private static let settings = SettingsStore()
    private static let store = ScanStore(settings: settings)

    private static let tab = ScannerTab()

    static var previews: some View {
        Group {
            view
                .previewDevice(PreviewDevice(rawValue: "iPhone 12 Pro"))
                .environment(\.colorScheme, .dark)
                .environment(\.fakeScan, true)

            view
                .previewDevice(PreviewDevice(rawValue: "iPad Pro (12.9-inch) (5th generation)"))
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

fileprivate struct FakeScanEnvironmentKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

fileprivate extension EnvironmentValues {
    var fakeScan: Bool {
        get {
            return self[FakeScanEnvironmentKey.self]
        }
        set {
            self[FakeScanEnvironmentKey.self] = newValue
        }
    }
}
