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

    let rootView = SavedScanListView()

    func makeCoordinator() -> Coordinator {
        Coordinator(self, modelData: scanStore)
    }

    func makeUIView(context: Context) -> UIScrollView {
        let control = UIScrollView()
        control.refreshControl?.addTarget(
            context.coordinator,
            action: #selector(Coordinator.handleRefreshControl),
            for: .valueChanged
        )


        let childView = UIHostingController(rootView: rootView)
        childView.view.frame = CGRect(x: 0, y: 0, width: width, height: height)

        control.addSubview(childView.view)
        return control
    }

    func updateUIView(_ uiView: UIScrollView, context: Context) {}
}



class Coordinator : NSObject {
    var control: SavedScanListScrollView
    var scanStore: ScanStore

    init(_ control: SavedScanListScrollView, modelData: ScanStore) {
        self.control = control
        self.scanStore = modelData
    }

    @objc
    func handleRefreshControl(sender: UIRefreshControl) {
        scanStore.update()
        sender.endRefreshing()
    }
}
