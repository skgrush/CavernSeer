//
//  SavedScanRow.swift
//  CavernSeer
//
//  Created by Samuel Grush on 7/6/20.
//  Copyright © 2020 Samuel K. Grush. All rights reserved.
//

import SwiftUI /// View

struct SavedScanRow: View {
    var preview: PreviewScanModel

    var image: Image?

    var body: some View {
        HStack {
            self.image
                .map {
                    $0
                        .resizable()
                        .frame(width: 50, height: 50)
                }

            Text(preview.id)

            Spacer()
        }
    }

    init(preview: PreviewScanModel, image: Image? = nil) {
        self.preview = preview
        self.image = image ?? makeSnapshot(preview: preview)
    }

    private func makeSnapshot(preview: PreviewScanModel) -> Image? {

        guard
            let imageData = preview.imageData,
            let uiImg = UIImage(data: imageData)
        else { return nil }

        return Image(uiImage: uiImg)
    }
}

//#if DEBUG
//struct SavedScanRow_Previews: PreviewProvider {
//    static var previews: some View {
//        Group {
//            SavedScanRow(model: dummyData[0])
//            SavedScanRow(model: dummyData[1])
//        }
//        .previewLayout(.fixed(width: 300, height: 70))
//    }
//}
//#endif
