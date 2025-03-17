//
//  Connection.swift
//  Swift3270
//
//  Created by Rudi on 2025-03-17.
//

import Foundation

class TNConnection {
let host: String
let port: Int
var inputStream: InputStream?
var outputStream: OutputStream?

init(host: String, port: Int) {
self.host = host
self.port = port
}

func connect() {
    var readStream: Unmanaged<CFReadStream>?
    var writeStream: Unmanaged<CFWriteStream>?

    CFStreamCreatePairWithSocketToHost(nil, host as CFString, UInt32(port), &readStream, &writeStream)

    inputStream = readStream?.takeRetainedValue()
    outputStream = writeStream?.takeRetainedValue()

    inputStream?.open()
    outputStream?.open()

    // Send data to the server
    // Implement your logic here

    print("Connected to \(host) on port \(port)")
    }

func disconnect() {
    inputStream?.close()
    outputStream?.close()
    print("Disconnected from server")
    }
}
