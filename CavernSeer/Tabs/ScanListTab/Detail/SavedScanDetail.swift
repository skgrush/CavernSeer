//
//  SavedScanDetail.swift
//  CavernSeer
//
//  Created by Samuel Grush on 7/6/20.
//  Copyright © 2020 Samuel K. Grush. All rights reserved.
//

import SwiftUI

struct SavedScanDetail: View {
    var model: SavedScanModel

    @State
    private var isPresentingRender = false
    @State
    private var isPresentingMap = false
    @State
    private var showShare = false

    var body: some View {
        VStack {
            /// side-by-side start and end snapshots
            HStack {
                self.showSnapshot(snapshot: self.model.scan.startSnapshot)
                    .map { styleSnapshot(img: $0) }
                self.showSnapshot(snapshot: self.model.scan.endSnapshot)
                    .map { styleSnapshot(img: $0) }
            }
            .frame(height: 300)

            Spacer()

            Text(model.id)
                .font(.title)
                .padding()

            List {
                NavigationLink(
                    destination: SavedScanDetailAdvanced(model: self.model)
                ) {
                    HStack {
                        Text("Advanced")
                    }
                }
                NavigationLink(
                    destination: MiniWorldRender(scan: self.model.scan)
                ) {
                    HStack {
                        Text("3D Render")
                    }
                }
                NavigationLink(
                    destination: ProjectedMiniWorldRender(scan: self.model.scan)
                ) {
                    HStack {
                        Text("Projected Render")
                    }
                }
                NavigationLink(
                    destination: FlatWorldRender(scan: self.model.scan)
                ) {
                    HStack {
                        Text("Map Render")
                    }
                }
            }

            Spacer()
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showShare = true }) {
                    Image(systemName: "square.and.arrow.up")
                        .font(Font.system(.title))
                }
            }
        }
        .sheet(isPresented: $showShare) {
            ScanShareSheet(activityItems: [model.url])
        }
    }

    private func showSnapshot(snapshot: SnapshotAnchor?) -> Image? {
        guard
            let imageData = snapshot?.imageData,
            let uiImg = UIImage(data: imageData)
        else { return nil }

        return Image(uiImage: uiImg)
    }

    private func styleSnapshot(img: Image) -> some View {
        return img
            .resizable()
            .scaledToFill()
            .frame(height: 300)
    }
}

#if DEBUG
struct SavedScanDetail_Previews: PreviewProvider {
    static var previews: some View {
        SavedScanDetail(model: dummyData[1])
    }
}
#endif
