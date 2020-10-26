//
//  SavedScanDetail.swift
//  CavernSeer
//
//  Created by Samuel Grush on 7/6/20.
//  Copyright © 2020 Samuel K. Grush. All rights reserved.
//

import SwiftUI /// View

struct SavedScanDetail: View {
    var model: SavedScanModel

    @EnvironmentObject
    var objSerializer: ObjSerializer

    @State
    private var isPresentingRender = false
    @State
    private var isPresentingMap = false
    @State
    private var showShare = false
    @State
    private var showObjPrompt = false
    @State
    private var showObjExport = false
    @State
    private var objExportUrl: URL?

    @State
    private var dummySelect: SurveyStation? = nil

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
                    destination: ProjectedMiniWorldRender(
                        scan: self.model.scan,
                        selection: $dummySelect
                    )
                ) {
                    HStack {
                        Text("Projected Render")
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
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showObjPrompt = true }) {
                    Image(systemName: "arrow.up.bin")
                        .font(Font.system(.title))
                }
            }
        }
        .sheet(isPresented: $showShare) {
            ScanShareSheet(activityItems: [model.url])
        }
        .sheet(isPresented: $showObjExport) {
            ScanShareSheet(activityItems: [objExportUrl!])
        }
        .alert(isPresented: $showObjPrompt) {
            Alert(
                title: Text("Export"),
                message: Text("Generate and export OBJ file?"),
                primaryButton: .destructive(Text("Export")) {
                    generateObj()
            }, secondaryButton: .cancel())
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

    private func generateObj() {
        let temporaryDirectoryURL = FileManager.default.temporaryDirectory
        let name = self.model.scan.name
            .replacingOccurrences(of: ":", with: "")
            .replacingOccurrences(of: "/", with: "")


        let tempUrl = temporaryDirectoryURL
            .appendingPathComponent(name)
            .appendingPathExtension("obj")

        self.objExportUrl = tempUrl

        DispatchQueue.global().async {
            do {
                try objSerializer.serializeScanViaMDL(
                    scan: self.model.scan,
                    url: tempUrl
                )
            } catch {
                fatalError("Error generating OBJ: \(error.localizedDescription)")
            }

            self.showObjPrompt = false
            self.showObjExport = true
        }
    }
}

#if DEBUG
struct SavedScanDetail_Previews: PreviewProvider {
    static var previews: some View {
        SavedScanDetail(model: dummyData[1])
    }
}
#endif
