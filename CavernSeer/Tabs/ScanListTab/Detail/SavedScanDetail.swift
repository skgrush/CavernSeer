//
//  SavedScanDetail.swift
//  CavernSeer
//
//  Created by Samuel Grush on 7/6/20.
//  Copyright © 2021 Samuel K. Grush. All rights reserved.
//

import SwiftUI /// View

class ObjTaskModel {
    /** Set to cancel the task before it's been initialized */
    var precancelled = false
    var objTask: Task<(), Error>?
}

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
    private var showObjLoading = false
    @State
    private var fileExt = "obj"

    @State
    private var taskModel = ObjTaskModel()

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
        .alert(Text("Export \(fileExt)?"), isPresented: $showObjPrompt) {
            Button(role: .destructive) {
                startGeneratingObj()
            } label: {
                Text("Export")
            }
            Button(role: .cancel) {
                self.showObjPrompt = false
            } label: {
                Text("Cancel")
            }
        } message: {
            Text("'\(model?.id ?? "scan")' to \(fileExt) file")
        }
        .alert(Text("Exporting..."), isPresented: $showObjLoading) {
            Button(role: .cancel) {
                if let objTask = self.taskModel.objTask {
                    objTask.cancel()
                    self.taskModel.objTask = nil
                } else {
                    // if you cancel before the task has initialized
                    self.taskModel.precancelled = true
                }
            } label: {
                Text("Cancel")
            }
        } message: {
            Text("Generating '\(model?.id ?? "scan").\(fileExt)';")
            Text("Once generated, share sheet will open file.")
        }
        .onAppear(perform: self.loadModel)
    }

    private func startGeneratingObj() {
        guard let model = self.model else {
            return
        }

        // give the UI time to close the alert which called this
        DispatchQueue.global(qos: .userInitiated).async {
            self.generateObjAsync(model: model)
        }
    }

    private func generateObjAsync(model: SavedScanModel) {
        self.taskModel.precancelled = false

        let temporaryDirectoryURL = FileManager.default.temporaryDirectory
        let name = model.id
            .replacingOccurrences(of: ":", with: "")
            .replacingOccurrences(of: "/", with: "")


        let tempUrl = temporaryDirectoryURL
            .appendingPathComponent(name)
            .appendingPathExtension(self.fileExt)

        self.showObjLoading = true

        // give the UI time to show the ObjLoading alert
        DispatchQueue.global(qos: .userInitiated).async {

            // create a task that can be cancelled
            self.taskModel.objTask = Task {
                try Task.checkCancellation()
                if self.taskModel.precancelled {
                    self.taskModel.precancelled = false
                    return
                }

                do {
                    try await objSerializer.serializeScanViaMDL(
                        scan: model.scan,
                        url: tempUrl
                    )
                } catch is CancellationError {
                    return // cancelled
                } catch {
                    fatalError(
                        "Error generating file: \(error.localizedDescription)"
                    )
                }

                try Task.checkCancellation()

                DispatchQueue.main.async {
                    self.showObjLoading = false

                    do {
                        try Task.checkCancellation()
                        self.taskModel.objTask = nil

                        DispatchQueue.main.asyncAfter(
                            deadline: .now() + 5
                        ) {
                            self.sharer.share([tempUrl])
                        }
                    } catch {
                        return
                    }
                }
            }
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
