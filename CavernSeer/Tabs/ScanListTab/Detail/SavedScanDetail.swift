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

            Spacer()

            Text(model?.id ?? "Loading...")
                .font(.title)
                .padding()

            if let model = self.model {
                SavedScanDetailLinks(model: model)
            }
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
            .scaledToFit()
            .frame(maxHeight: 300)
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

#if DEBUG
struct SavedScanDetail_Previews: PreviewProvider {
    private static let settings = SettingsStore()
    private static let scanStore = setupScanStore()
    private static let serializer = ObjSerializer()

    private static let preview = dummyPreviewScans[1]

    static var previews: some View {
        Group {
            view
                .previewDevice(PreviewDevice(rawValue: "iPhone 12 Pro"))
                .environment(\.colorScheme, .dark)

            view
                //.previewDevice(PreviewDevice(rawValue: "iPhone 8"))
                .previewDisplayName("iPhone 8 Landscape")
                .previewLayout(PreviewLayout.fixed(width: 667, height: 375))

//            view
//                .previewLayout(.fixed(width: 1024, height: 768))
        }
        .environmentObject(scanStore)
        .environmentObject(settings)
        .environmentObject(serializer)
    }

    private static var view: some View {
        TabView {
            NavigationView {
                List {
                    NavigationLink(
                        destination: SavedScanDetail(url: preview.url),
                        isActive: Binding(get: { true }, set: {_,_ in }),
                        label: { SavedScanRow(preview: preview) }
                    )
                }
            }
        }
    }

    private static func setupScanStore() -> ScanStore {
        let store = ScanStore()

        store.cachedModelData = dummySavedScans
        store.previews = dummyPreviewScans

        return store
    }
}
#endif
