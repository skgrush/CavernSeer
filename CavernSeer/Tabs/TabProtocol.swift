//
//  TabProtocol.swift
//  CavernSeer
//
//  Created by Samuel Grush on 6/27/20.
//  Copyright © 2020 Samuel K. Grush. All rights reserved.
//

import Foundation
import SwiftUI /// Image, AnyView

protocol TabProtocol {

    var tab: Tabs { get }
    var tabName: String { get }
    var tabImage: Image { get }

    var tabPanelView: AnyView { get }
}
