//
//  SavedScanDetailAdvanced.swift
//  CavernSeer
//
//  Created by Samuel Grush on 7/7/20.
//  Copyright © 2020 Samuel K. Grush. All rights reserved.
//

import SwiftUI /// View
import ARKit /// ARMeshAnchor

struct SavedScanDetailAdvanced: View {
    var model: SavedScanModel

    private var totalVertices: Int {
        model.scan.meshAnchors.map {
            anchor in anchor.geometry.vertices.count
        }.reduce(0, { acc, next in acc + next })
    }

    private var totalFaces: Int {
        model.scan.meshAnchors.map {
            anchor in anchor.geometry.faces.count
        }.reduce(0, { acc, next in acc + next })
    }

    var body: some View {
        VStack {
            GroupBox(label: Text("WorldMap Attributes")) {
                Text("center: \(model.scan.center.description)")
                Text("extent: \(model.scan.extent.description)")
                Text("anchor count: \(model.scan.meshAnchors.count)")
                Text("vertex count: \(totalVertices)")
                Text("triangle count: \(totalFaces)")
                Text("URL: \(model.url.absoluteString)")
                Text("file size: \(showMegabytes(amount: model.fileSize))")
            }

            GroupBox(label: Text("Anchors")) {
                List(model.scan.meshAnchors, id: \.identifier) {
                    anchor in
                    NavigationLink(
                        destination: MeshAnchorDetail(anchor: anchor)
                    ) {
                        HStack {
                            Text(anchor.description)
                            Spacer()
                        }
                    }
                }
            }
            GroupBox(label: Text("Stations")) {
                List(model.scan.stations, id: \.identifier) {
                    station in
                    HStack {
                        Text(station.identifier.uuidString)
                        Text(station.transform.debugDescription)
                    }
                }
            }
            GroupBox(label: Text("Lines")) {
                List(model.scan.lines, id: \.identifier) {
                    line in
                    HStack {
                        Text(line.startIdentifier.uuidString)
                        Text(line.endIdentifier.uuidString)
                    }
                }
            }
        }
    }

    private func showMegabytes(amount: Int64)-> String {
        let byteFormatter = ByteCountFormatter()
        byteFormatter.allowedUnits = [.useMB, .useKB]
        byteFormatter.countStyle = .file

        return byteFormatter.string(fromByteCount: amount)
    }

}


struct MeshAnchorDetail: View {
    var anchor: ARMeshAnchor

    var body: some View {
        VStack {
            Text(anchor.description)
                .font(.title)
            VStack {
                Text("transform: \(anchor.transform.debugDescription)")
                Text("Vertex count: \(anchor.geometry.vertices.count)")
                Text("Normal count: \(anchor.geometry.normals.count)")
                Text("Face count: \(anchor.geometry.faces.count)")
            }
        }
    }
}

#if DEBUG
struct SavedScanDetailAdvanced_Previews: PreviewProvider {
    static var previews: some View {
        SavedScanDetailAdvanced(model: dummyData[1])
    }
}
#endif
