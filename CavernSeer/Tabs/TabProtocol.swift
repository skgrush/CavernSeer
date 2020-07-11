//
//  TabProtocol.swift
//  CavernSeer
//
//  Created by Samuel Grush on 6/27/20.
//  Copyright © 2020 Samuel K. Grush. All rights reserved.
//

import Foundation
import SwiftUI



protocol TabProtocol {
    associatedtype ViewType: View

    // var tabPanelView: ViewType { get }
    var tab: Tabs { get }
    var tabName: String { get }
    var tabImage: Image { get }

    func tabPanelView() -> ViewType
}
