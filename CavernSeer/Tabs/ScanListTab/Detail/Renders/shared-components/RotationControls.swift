//
//  RotationControls.swift
//  CavernSeer
//
//  Created by Samuel Grush on 12/3/20.
//  Copyright © 2020 Samuel K. Grush. All rights reserved.
//

import SwiftUI

struct RotationControls: View {

    @Binding
    var rotation: Int

    var body: some View {
        Stepper(
            onIncrement: { clampRotation(+5) },
            onDecrement: { clampRotation(-5) },
            label: {
                Text("\(rotation)ºN")
                + Text("m").font(.system(size: 8)).baselineOffset(0)
            }
        )
            .frame(width: 155)

        Button(action: { clampRotation(-90) }) {
            Image(systemName: "gobackward.90")
        }
        Button(action: { clampRotation(+90) }) {
            Image(systemName: "goforward.90")
        }
    }

    /**
     * Clamp rotation to `[0,360)`, "overflowing" and "underflowing" on boundaries
     */
    private func clampRotation(_ delta: Int) {
        self.rotation = (self.rotation + delta + 360) % 360
    }
}

//#if DEBUG
//struct RotationControls_Previews: PreviewProvider {
//    static var previews: some View {
//        RotationControls()
//    }
//}
//#endif
