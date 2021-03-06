//
//  SavedScanRow.swift
//  CavernSeer
//
//  Created by Samuel Grush on 7/6/20.
//  Copyright © 2020 Samuel K. Grush. All rights reserved.
//

import SwiftUI /// View

struct SavedScanRow: View {
    var cache: ScanCacheFile

    var image: Image?

    var body: some View {
        HStack {
            self.image
                .map {
                    $0
                        .resizable()
                        .frame(width: 50, height: 50)
                }

            Text(cache.id)

            Spacer()
        }
    }

    init(cache: ScanCacheFile, image: Image? = nil) {
        self.cache = cache
        self.image = image ?? makeSnapshot(data: cache.jpegImageData)
    }

    private func makeSnapshot(data: Data?) -> Image? {

        guard
            let imageData = data,
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
