//
//  ShareSheetService.swift
//  CavernSeer
//
//  Created by Samuel Grush on 12/25/21.
//  Copyright © 2021 Samuel K. Grush. All rights reserved.
//

import Foundation
import SwiftUI

enum ImageType {
    case jpeg
    case png
}

extension ImageType {
    var ext: String {
        switch self {
            case .jpeg:
                return "jpeg"
            case .png:
                return "png"
        }
    }
}

enum FileShareError : Error {
    case dataError
    case writeError(Error)
}


class ShareSheetUtility : ObservableObject {

    /**
     * Share a `UIImage`
     *
     * - Throws: `ShareError` only on macOS where we convert to data;
     *      `dataError` if the image could not be converted to data,
     *      `writeError` if an error occurred while writing.
     */
    func shareImage(
        _ img: UIImage,
        type: ImageType,
        basename: String? = nil
    ) throws {

        if ProcessInfo.processInfo.isiOSAppOnMac {
            let data = try imgToData(img, type: type)

            let nameAndExt = basename != nil
                ? (basename!, type.ext)
                : nil
            try shareData(data, nameAndExt: nameAndExt)
        } else {
            share([img])
        }
    }

    /**
     * Share any data object as a file.
     *
     * - Throws: `ShareError` only on macOS where we convert to data;
     *      `dataError` if the image could not be converted to data,
     *      `writeError` if an error occurred while writing.
     */
    func shareData(
        _ data: Data,
        nameAndExt: (basename: String, ext: String)? = nil
    ) throws {
        let tmpFolder = FileManager.default.temporaryDirectory
        let tmpFile: URL
        if let (basename, ext) = nameAndExt {
            tmpFile = tmpFolder
                .appendingPathComponent(basename)
                .appendingPathExtension(ext)
        } else {
            tmpFile = tmpFolder.appendingPathComponent(UUID().uuidString)
        }

        do {
            try data.write(to: tmpFile)
        } catch {
            throw FileShareError.writeError(error)
        }

        share([tmpFile])
    }

    func share(_ items: [Any]) {
        let actVC = UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )

        let scenes = UIApplication.shared.connectedScenes
            .filter { $0.activationState == .foregroundActive }
            .compactMap { $0 as? UIWindowScene }

        guard let scene = (scenes.first)
        else {
            debugPrint("No foreground UIWindowScene")
            return
        }

        guard
            let keyWindow = (scene.windows.first { $0.isKeyWindow }),
            let rootController = keyWindow.rootViewController
        else {
            debugPrint("No key window found")
            return
        }

        rootController.present(actVC, animated: true)
    }

    private func imgToData(_ img: UIImage, type: ImageType) throws -> Data {
        if
            let data = type == .jpeg
                ? img.jpegData(compressionQuality: 1)
                : img.pngData()
        {
            return data
        }

        throw FileShareError.dataError
    }
}
