//
//  SavedScanListScrollView.swift
//  CavernSeer
//
//  Created by Samuel Grush on 7/6/20.
//  Copyright © 2020 Samuel K. Grush. All rights reserved.
//

import SwiftUI

struct SavedScanListScrollView: UIViewRepresentable {

    var width: CGFloat
    var height: CGFloat

    @EnvironmentObject
    var scanStore: ScanStore

    func makeCoordinator() -> Coordinator {
        Coordinator(modelData: scanStore, height: height)
    }

    func makeUIView(context: Context) -> UIScrollView {
        let control = UIScrollView()
        control.refreshControl = UIRefreshControl()
        control.refreshControl?.addTarget(
            context.coordinator,
            action: #selector(Coordinator.handleRefreshControl),
            for: .valueChanged
        )

        context.coordinator.height = height

        let idealSize = min(height, width) - 100
        let uiHost = UIHostingController(rootView: SavedScanListView())
        // context.coordinator.uiHost = uiHost
        uiHost.view.frame = CGRect(x: 0, y: 0, width: 333, height: idealSize)

        control.addSubview(uiHost.view)

        scanStore.update()

        return control
    }

    func updateUIView(_ uiView: UIScrollView, context: Context) {
        context.coordinator.height = height
    }
}



class Coordinator : NSObject {
    var scanStore: ScanStore

    // var uiHost: UIHostingController<SavedScanListView>?
    var height: CGFloat

    var relayout = false

    init(modelData: ScanStore, height: CGFloat) {
        self.scanStore = modelData
        self.height = height
    }

    @objc
    func handleRefreshControl(sender: UIRefreshControl) {
        scanStore.update()
        DispatchQueue.main.async {
            sender.endRefreshing()
        }
    }
}
