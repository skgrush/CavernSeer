//
//  ElevationCrossSectionRender.swift
//  CavernSeer
//
//  Created by Samuel Grush on 12/3/20.
//  Copyright © 2020 Samuel K. Grush. All rights reserved.
//

import SwiftUI

struct ElevationCrossSectionRender: View {

    private static let CrossSectionDepth = 0.5

    var scan: ScanFile

    var color: UIColor?
    var ambientColor: Color?
    var quiltMesh: Bool

    @State
    private var doCrossSection = false

    @State
    private var depthOfField: Double?

    var body: some View {
        ZStack {
            ElevationProjectedMiniWorldRender(
                scan: scan,
                color: color,
                ambientColor: ambientColor,
                quiltMesh: quiltMesh,
                barSubview: barSubview, 
                depthOfField: depthOfField
            )
        }
    }

    private var barSubview: AnyView {
        AnyView(
            Toggle("X", isOn: $doCrossSection)
                .frame(maxWidth: 50)
                .onChange(of: doCrossSection) {
                    x
                    in
                    depthOfField = x ? Self.CrossSectionDepth : nil
                }
        )
    }
}

//#if DEBUG
//struct ElevationCrossSectionRender_Previews: PreviewProvider {
//    static var previews: some View {
//        ElevationCrossSectionRender()
//    }
//}
//#endif
