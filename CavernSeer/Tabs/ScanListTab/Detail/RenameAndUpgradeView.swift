//
//  RenameAndUpgradeView.swift
//  CavernSeer
//
//  Created by Samuel Grush on 6/6/21.
//  Copyright © 2021 Samuel K. Grush. All rights reserved.
//

import Foundation
import SwiftUI

struct RenameAndUpgradeView : View {
    var scan: ScanFile

    @EnvironmentObject
    var scanStore: ScanStore

    @State
    private var showingRename: Bool = false
    @State
    private var newName: String = ""

    @State
    private var showingResultAlert: Bool = false
    @State
    private var resultURL: URL?
    @State
    private var resultMessage: String = ""

    private var canUpgrade: Bool {
        scan.encodingVersion < ScanFile.currentEncodingVersion
    }

    var body: some View {
        GroupBox(label: label) {
            if canUpgrade {
                Text(
                    "File can be upgraded from \(scan.encodingVersion) " +
                    "to \(ScanFile.currentEncodingVersion)"
                )
            }
            if !showingRename {
                Button(action: {
                    showingRename = true
                    newName = scan.name
                }) {
                    Text(canUpgrade ? "Upgrade" : "Copy and Rename")
                }
            } else {
                VStack {
                    TextField(
                        "Name",
                        text: $newName,
                        onCommit: save
                    )
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .border(Color(UIColor.separator))

                    HStack(spacing: 20) {
                        Button(action: { save() }) {
                            Text("Save")
                        }
                        Button(action: { cancel() }) {
                            Text("Cancel")
                                .foregroundColor(Color(UIColor.systemRed))
                        }
                    }
                }
            }
        }
        .alert(
            Text(resultURL != nil ? "Successfully wrote file" : "Error writing file!"),
            isPresented: $showingResultAlert
        ) {
            Button("Ok", role: nil) {
                if let resultURL = resultURL {
                    scanStore.setVisible(visible: resultURL, updateFirst: true)
                }
            }
        }
    }

    private var label: Text {
        return Text(
            canUpgrade
                ? "File Version Upgrade"
                : "File Copy"
        )
    }

    private func showRename() {
        newName = scan.name
        showingResultAlert = false
        showingRename = true
    }

    private func cancel() {
        showingRename = false
        showingResultAlert = false
    }

    private func save() {
        do {
            self.resultURL = try scanStore.copySaveFile(
                scanFile: scan,
                name: newName,
                withLocation: true
            )
            self.resultMessage = "\(self.resultURL!)"
        } catch {
            self.resultURL = nil
            resultMessage = error.localizedDescription
        }

        newName = ""
        showingRename = false
        showingResultAlert = true
    }
}
