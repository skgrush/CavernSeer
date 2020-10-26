//
//  ScanShareSheet.swift
//  CavernSeer
//
//  Created by Samuel Grush on 7/8/20.
//  Copyright © 2020 Samuel K. Grush. All rights reserved.
//

import SwiftUI /// UIViewControllerRepresentable, Context

struct ScanShareSheet: UIViewControllerRepresentable {
    typealias Callback = (_ activityType: UIActivity.ActivityType?,
                          _ completed: Bool,
                          _ returnedItems: [Any]?,
                          _ error: Error?) -> Void

    let activityItems: [URL]
    let applicationActivities: [UIActivity]? = nil
    let excludedActivityTypes: [UIActivity.ActivityType]? = nil
    let callback: Callback? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: applicationActivities)
        controller.excludedActivityTypes = excludedActivityTypes
        controller.completionWithItemsHandler = callback
        return controller
    }

    func updateUIViewController(
        _ uiViewController: UIActivityViewController,
        context: Context
    ) {
        // nothing to do here
    }
}
