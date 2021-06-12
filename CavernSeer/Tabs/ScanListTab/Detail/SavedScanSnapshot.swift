//
//  SavedScanSnapshot.swift
//  CavernSeer
//
//  Created by Samuel Grush on 6/8/21.
//  Copyright © 2021 Samuel K. Grush. All rights reserved.
//

import SwiftUI

struct SavedScanSnapshot: View {
    var scan: ScanFile?

    @State
    var showShare = false
    @State
    var shareImg: UIImage?

    var body: some View {
        HStack {
            self.showSnapshot(snapshot: scan?.startSnapshot)
                .map { styleAndAddContextMenu(uiImg: $0) }
            self.showSnapshot(snapshot: scan?.endSnapshot)
                .map { styleAndAddContextMenu(uiImg: $0) }
        }
    }

    private func showSnapshot(snapshot: CSMeshSnapshot?) -> UIImage? {
        guard
            let imageData = snapshot?.imageData,
            let uiImg = UIImage(data: imageData)
        else { return nil }

        return uiImg
    }

    private func styleAndAddContextMenu(uiImg: UIImage) -> some View {
        return Image(uiImage: uiImg)
            .resizable()
            .scaledToFit()
            .contextMenu {
                Button {
                    copyImage(uiImg: uiImg)
                } label: {
                    Label("Copy", systemImage: "doc.on.doc")
                }
                Button {
                    shareImage(uiImg: uiImg)
                } label: {
                    Label("Share", systemImage: "square.and.arrow.up")
                }
            }
            .frame(maxHeight: 300)
    }

    private func copyImage(uiImg: UIImage) {
        let pasteboard = UIPasteboard.general
        pasteboard.image = uiImg
    }

    private func shareImage(uiImg: UIImage) {
        let actVC = UIActivityViewController(
            activityItems: [uiImg],
            applicationActivities: nil
        )
        UIApplication.shared.windows.first?.rootViewController?
            .present(actVC, animated: true)
    }
}

struct SavedScanSnapshot_Previews: PreviewProvider {
    static var previews: some View {
        SavedScanSnapshot()
    }
}
