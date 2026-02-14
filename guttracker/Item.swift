//
//  Item.swift
//  guttracker
//
//  Created by gilko on 2026/2/14.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
