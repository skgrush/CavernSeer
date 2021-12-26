//
//  SavedScanDetail.swift
//  CavernSeer
//
//  Created by Samuel Grush on 7/6/20.
//  Copyright © 2021 Samuel K. Grush. All rights reserved.
//

import SwiftUI /// View

struct SavedScanDetail: View {
    var cache: ScanCacheFile

    @EnvironmentObject
    var objSerializer: ObjSerializer
    @EnvironmentObject
    var sharer: ShareSheetUtility
    @EnvironmentObject
    var settings: SettingsStore
    @EnvironmentObject
    var scanStore: ScanStore

    @State
    var error: Error?

    @State
    private var model: SavedScanModel? = nil
    @State
    private var isPresentingRender = false
    @State
    private var isPresentingMap = false
    @State
    private var showObjPrompt = false
    @State
    private var showExportLoading = false
    @State
    private var fileExt = "obj"

    private func loadModel() {
        if let err = self.cache.error {
            self.error = err
            return
        }

        let url = scanStore.getNormalizedRealUrl(cache: self.cache)
        if self.model?.url != url {
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

            SavedScanSnapshot(scan: model?.scan)

            Spacer()

            Text(model?.id ?? error?.localizedDescription ?? "Loading...")
                .font(.title)
                .padding()

            if let model = self.model {
                SavedScanDetailLinks(model: model)
            }
        }
        .navigationBarItems(
            trailing: HStack {
                Button(
                    action: { self.sharer.share([model!.url]) },
                    label: { Image(systemName: "square.and.arrow.up") }
                )
                Button(
                    action: { self.showObjPrompt = true },
                    label: { Image(systemName: "arrow.up.bin") }
                )
            }
        )
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
        .onAppear(perform: self.loadModel)
    }

    private func generateObj() {
        guard let model = self.model else {
            return
        }

        self.showObjPrompt = false
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
            self.sharer.share([tempUrl])
        }
    }
}

#if DEBUG
struct SavedScanDetail_Previews: PreviewProvider {
    private static let settings = SettingsStore()
    private static let scanStore = setupScanStore(settings: settings)
    private static let serializer = ObjSerializer()

    private static let cacheItem = dummyScanCaches[1]

    static var previews: some View {
        Group {
            view
                .previewDevice(PreviewDevice(rawValue: "iPhone 12 Pro"))
                .environment(\.colorScheme, .dark)

            view
                .previewDevice(PreviewDevice(rawValue: "iPad Pro (12.9-inch) (5th generation)"))
                .environment(\.colorScheme, .dark)

            view
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
                        destination: SavedScanDetail(cache: cacheItem),
                        isActive: Binding(get: { true }, set: {_,_ in }),
                        label: { SavedScanRow(cache: cacheItem) }
                    )
                }
            }
        }
    }

    private static func setupScanStore(settings: SettingsStore) -> ScanStore {
        let store = ScanStore(settings: settings)

        store.modelDataInMemory = dummySavedScans
        store.caches = dummyScanCaches

        return store
    }
}
#endif
