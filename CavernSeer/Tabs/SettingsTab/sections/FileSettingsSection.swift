//
//  FileSettingsSection.swift
//  CavernSeer
//
//  Created by Samuel Grush on 5/30/21.
//  Copyright © 2021 Samuel K. Grush. All rights reserved.
//

import Foundation
import SwiftUI

struct FileSettingsSection: View {
    @EnvironmentObject
    var scanStore: ScanStore

    @State
    var showDeletePrompt = false

    var body: some View {
        Group() {
            HStack {
                Button(action: clear) {
                    Text("Clear caches")
                }
            }
            HStack {
                Button(action: buildCaches) {
                    Text("Build caches")
                }
            }
            HStack {
                Button(action: { showDeletePrompt = true }) {
                    Text("Delete all stored files")
                        .foregroundColor(Color(UIColor.systemRed))
                }
                .confirmationDialog(
                    Text("Delete all files stored in the app? This cannot be undone!"),
                    isPresented: $showDeletePrompt,
                    titleVisibility: .visible
                ) {
                    Button("Delete all", role: .destructive) {
                        deleteAllFiles()
                    }
                    Button("Cancel", role: .cancel) {
                        showDeletePrompt = false
                    }
                }
            }
        }
    }

    private func clear() {
        do {
            try self.scanStore.clearCaches()
        } catch {
            fatalError("Failed to clear caches: \(error.localizedDescription)")
        }
    }

    private func buildCaches() {
        self.scanStore.update() {
            err in
            if err != nil {
                fatalError(
                    "Failed to rebuild caches: " +
                    err!.localizedDescription
                )
            }
        }
    }

    private func deleteAllFiles() {
        do {
            try self.scanStore.DANGEROUSLY_deleteAllFiles()
        } catch {
            fatalError("Failed to delete all files: \(error.localizedDescription)")
        }
    }
}
