//
//  Item.swift
//  Swift3270
//
//  Created by Rudi on 2025-03-16.
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
