//
//  UserDefaults+color.swift
//  CavernSeer
//
//  Created by Samuel Grush on 11/15/20.
//  Copyright © 2020 Samuel K. Grush. All rights reserved.
//

import Foundation
import SwiftUI

extension UserDefaults {
    func color(forKey: String) -> Color? {
        if let colorData = self.data(forKey: forKey) {
            do {
                return try NSKeyedUnarchiver
                        .unarchiveTopLevelObjectWithData(colorData) as? Color
            } catch {
                debugPrint("Color unarchive error:", error)
            }
        }

        return nil
    }

    /**
     * Sets the color value of the specified default key.
     */
    func set(_ color: Color?, forKey: String) {
        if let color = color {
            do {
                let colorData = try NSKeyedArchiver.archivedData(
                    withRootObject: color,
                    requiringSecureCoding: false
                ) as Data
                self.set(colorData, forKey: forKey)
            } catch {
                fatalError(
                    "Failed setting color data: \(error.localizedDescription)"
                )
            }
        } else {
            self.removeObject(forKey: forKey)
        }
    }
}
