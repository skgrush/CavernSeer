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
        do {
            try self.scanStore.update()
        } catch {
            fatalError("Building cache failed: \(error.localizedDescription)")
        }
    }
}
