//
//  SavedScanRow.swift
//  CavernSeer
//
//  Created by Samuel Grush on 7/6/20.
//  Copyright © 2020 Samuel K. Grush. All rights reserved.
//

import SwiftUI

struct SavedScanRow: View {
    var model: SavedScanModel

    var body: some View {
        HStack {
            self.showSnapshot(snapshot: model.scan.startSnapshot)
                .map {
                    $0
                        .resizable()
                        .frame(width: 50, height: 50)
                }

            Text(model.id)

            Spacer()
        }
    }

    func showSnapshot(snapshot: SnapshotAnchor?) -> Image? {
        guard
            let imageData = snapshot?.imageData,
            let uiImg = UIImage(data: imageData)
        else { return nil }

        return Image(uiImage: uiImg)
    }

//    func styleSnapshot(img: Image) -> some View {
//        return img
//            .resizable()
//            .scaledToFill()
//            .frame(height: 300)
//    }
}

#if DEBUG
struct SavedScanRow_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            SavedScanRow(model: dummyData[0])
            SavedScanRow(model: dummyData[1])
        }
        .previewLayout(.fixed(width: 300, height: 70))
    }
}
#endif
