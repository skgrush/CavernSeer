//
//  DebugSection.swift
//  CavernSeer
//
//  Created by Samuel Grush on 12/7/21.
//  Copyright © 2021 Samuel K. Grush. All rights reserved.
//

import SwiftUI

struct DebugSection: View {

    private static let githubURL = URL(string: "https://cavernseer.grush.org/github")!

    let keys = [
        ("CFBundleShortVersionString", "Version"),
        ("CFBundleVersion", "Build"),
        ("CS:PlatformTargetPrefix", "Platform Target"),
        ("MinimumOSVersion", "MinimumOSVersion"),

    ]

    var body: some View {
        Group() {

            ForEach(keys, id: \.1) {
                (key, label) in
                HStack {
                    Text(label).fontWeight(.light)
                    Spacer()
                    Text(getInfo(key: key))
                }
            }

            HStack {
                Text("View source").fontWeight(.light)
                Spacer()
                Link("GitHub", destination: Self.githubURL)
            }
        }
    }

    private func getInfo(key: String) -> String {
        Bundle.main.infoDictionary?[key] as? String ?? "Error"
    }
}

#if DEBUG
struct DebugSection_Previews: PreviewProvider {
    static var previews: some View {
        DebugSection()
    }
}
#endif
