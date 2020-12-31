//
//  SavedScanDetail.swift
//  CavernSeer
//
//  Created by Samuel Grush on 7/6/20.
//  Copyright © 2020 Samuel K. Grush. All rights reserved.
//

import SwiftUI /// View

struct SavedScanDetail: View {
    var url: URL

    @EnvironmentObject
    var objSerializer: ObjSerializer
    @EnvironmentObject
    var settings: SettingsStore
    @EnvironmentObject
    var scanStore: ScanStore

    @State
    private var model: SavedScanModel? = nil
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
    private var showExportLoading = false
    @State
    private var objExportUrl: URL?
    @State
    private var fileExt = "obj"

    @State
    private var dummySelect: SurveyStation? = nil

    private var meshColor: UIColor? {
        let cgColor = settings.ColorMesh?.cgColor
        if cgColor != nil && cgColor!.alpha > 0.05 {
            return UIColor(cgColor: cgColor!)
        }
        return nil
    }

    private func loadModel() {
        if self.model?.url != self.url {
            do {
                self.model = try scanStore.getModel(url: url)
            } catch {
                fatalError("Failed to find model: \(error.localizedDescription)")
            }
        }
    }

    var body: some View {
        VStack {
            if showExportLoading {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Exporting '\(self.fileExt)' file...").bold()
                        Text(self.model?.scan.name ?? "ERROR finding scan name")
                    }
                    Spacer()
                }
                .padding(12)
                .background(Color.green)
                .cornerRadius(8)
            }

            /// side-by-side start and end snapshots
            HStack {
                self.showSnapshot(snapshot: self.model?.scan.startSnapshot)
                    .map { styleSnapshot(img: $0) }
                self.showSnapshot(snapshot: self.model?.scan.endSnapshot)
                    .map { styleSnapshot(img: $0) }
            }
            .frame(height: 300)

            Spacer()

            Text(model?.id ?? "Loading...")
                .font(.title)
                .padding()

            if let model = self.model {
                List {
                    NavigationLink(
                        destination: SavedScanDetailAdvanced(model: model)
                    ) {
                        HStack {
                            Text("Advanced")
                        }
                    }
                    NavigationLink(
                        destination: MiniWorldRender(
                            scan: model.scan,
                            color: meshColor,
                            ambientColor: settings.ColorLightAmbient,
                            quiltMesh: settings.ColorMeshQuilt
                        )
                    ) {
                        HStack {
                            Text("3D Render")
                        }
                    }
                    NavigationLink(
                        destination: ProjectedMiniWorldRender(
                            scan: model.scan,
                            color: meshColor,
                            ambientColor: settings.ColorLightAmbient,
                            quiltMesh: settings.ColorMeshQuilt,
                            selection: $dummySelect
                        )
                    ) {
                        HStack {
                            Text("Plan Projected Render")
                        }
                    }
                    NavigationLink(
                        destination: ElevationProjectedMiniWorldRender(
                            scan: model.scan,
                            color: meshColor,
                            ambientColor: settings.ColorLightAmbient,
                            quiltMesh: settings.ColorMeshQuilt,
                            selection: $dummySelect
                        )
                    ) {
                        HStack {
                            Text("Elevation Projected Render")
                        }
                    }
                }
            }

            Spacer()
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    self.showObjExport = false
                    self.showShare = true

                }) {
                    Image(systemName: "square.and.arrow.up")
                        .font(Font.system(.title))
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { self.showObjPrompt = true }) {
                    Image(systemName: "arrow.up.bin")
                        .font(Font.system(.title))
                }
            }
        }
        .sheet(isPresented: $showShare) {
            if let model = self.model {
                ScanShareSheet(activityItems: [
                    self.showObjExport ? self.objExportUrl! : model.url
                ])
            }
        }
        .alert(isPresented: $showObjPrompt) {
            Alert(
                title: Text("Export"),
                message: Text("Generate and export '\(self.fileExt)' file?"),
                primaryButton: .destructive(Text("Export")) {
                    generateObj()
                },
                secondaryButton: .cancel()
            )
        }
        .onAppear(perform: { self.loadModel() })
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
        guard let model = self.model else {
            return
        }

        self.showObjPrompt = false
        self.showShare = false
        DispatchQueue.global().async {
            self.showExportLoading = true
        }

        let temporaryDirectoryURL = FileManager.default.temporaryDirectory
        let name = model.scan.name
            .replacingOccurrences(of: ":", with: "")
            .replacingOccurrences(of: "/", with: "")


        let tempUrl = temporaryDirectoryURL
            .appendingPathComponent(name)
            .appendingPathExtension(self.fileExt)

        self.objExportUrl = tempUrl

        DispatchQueue.global().async {
            do {
                try objSerializer.serializeScanViaMDL(
                    scan: model.scan,
                    url: tempUrl
                )
            } catch {
                fatalError(
                    "Error generating file: \(error.localizedDescription)"
                )
            }

            self.showExportLoading = false
            self.showObjExport = true
            self.showShare = true
        }
    }
}

//#if DEBUG
//struct SavedScanDetail_Previews: PreviewProvider {
//    static var previews: some View {
//        SavedScanDetail(model: dummyData[1])
//    }
//}
//#endif
