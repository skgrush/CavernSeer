//
//  StoredFileProtocol.swift
//  CavernSeer
//
//  Created by Samuel Grush on 12/30/20.
//  Copyright © 2020 Samuel K. Grush. All rights reserved.
//

import Foundation

protocol StoredFileProtocol : NSObject, NSSecureCoding {
    static var filePrefix: String { get }
    static var fileExtension: String { get }
    var timestamp: Date { get }
    var name: String { get }
}

extension StoredFileProtocol {
    static func makeDefaultBaseName(
        with date: Date,
        as format: DateFormatter
    ) -> String {
        let datestr = format.string(from: date)
        return "\(Self.filePrefix)_\(datestr)"
    }

    static func getDefaultDateFormatter(
        tz: TimeZone = .current
    ) -> DateFormatter {
        let fmt = DateFormatter()
        fmt.timeZone = tz
        fmt.dateFormat = "yyyy-MM-dd'T'HHmmssZ"
        return fmt
    }
}
