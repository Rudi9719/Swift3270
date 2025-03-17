//
//  HostConnection.swift
//  Swift3270
//
//  Created by Rudi on 2025-03-16.
//

import Foundation
import SwiftData

@Model
final class HostSettings {
    var creationTimestamp: Date
    var hostName: String
    var nickname: String?
    var port: Int
    var ssl: Bool = false
    var model: Int = 4
    
    
    init(timestamp: Date, hostname: String, port: Int = 3270, nickname: String? = nil) {
        self.creationTimestamp = timestamp
        self.hostName = hostname
        self.port = port
        self.nickname = nickname
        
    }
    
    func getConnection() -> TNConnection {
        return TNConnection(host: hostName, port: port)
    }
    
    
}


