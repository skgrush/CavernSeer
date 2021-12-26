//
//  SavedScanSnapshot.swift
//  CavernSeer
//
//  Created by Samuel Grush on 6/8/21.
//  Copyright © 2021 Samuel K. Grush. All rights reserved.
//

import SwiftUI

struct SavedScanSnapshot: View {

    @EnvironmentObject
    var shareImage: ShareSheetUtility

    var scan: ScanFile?

    var body: some View {
        HStack {
            self.showSnapshot(snapshot: scan?.startSnapshot)
                .map { styleAndAddContextMenu(uiImg: $0, suffix: "start") }
            self.showSnapshot(snapshot: scan?.endSnapshot)
                .map { styleAndAddContextMenu(uiImg: $0, suffix: "end") }
        }
    }

    private func showSnapshot(snapshot: CSMeshSnapshot?) -> UIImage? {
        guard
            let imageData = snapshot?.imageData,
            let uiImg = UIImage(data: imageData)
        else { return nil }

        return uiImg
    }

    private func styleAndAddContextMenu(uiImg: UIImage, suffix: String) -> some View {
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
                    shareImage(uiImg: uiImg, suffix: suffix)
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

    private func shareImage(uiImg: UIImage, suffix: String) {
        let bn = "\(scan!.name) \(suffix).jpg"
        do {
            try self.shareImage.shareImage(uiImg, type: .jpeg, basename: bn)
        } catch {
            fatalError("Error sharing image \(error)")
        }
    }
}

struct SavedScanSnapshot_Previews: PreviewProvider {
    static var previews: some View {
        SavedScanSnapshot()
    }
}
