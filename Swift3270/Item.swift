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
    var host: String
    var port: UInt16
    
    @Transient
    var connection: TN3270? = nil
    
    init (host: String, port: UInt16) {
        self.host = host
        self.port = port
        self.timestamp = Date()
        connection = TN3270(host: host, port: port, model: "IBM-3279-4-E")
    }
    
}
