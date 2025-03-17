//
//  Connection.swift
//  Swift3270
//
//  Created by Rudi on 2025-03-17.
//

import Foundation
import NIO

enum TCPClientError: Error {
    case invalidHost
    case invalidPort
}

class TNConnection {
    private let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
    let host: String
    let port: Int
    
    init(host: String, port: Int) {
        self.host = host
        self.port = port
    }
    
    
      func start() throws {
          do {
              let channel = try bootstrap.connect(host: host, port: port).wait()
              try channel.closeFuture.wait()
          } catch let error {
              throw error
          }
      }
      
      func stop() {
          do {
              try group.syncShutdownGracefully()
          } catch let error {
              print("Error shutting down \(error.localizedDescription)")
              exit(0)
          }
          print("Client connection closed")
      }
      
      private var bootstrap: ClientBootstrap {
          return ClientBootstrap(group: group)
              .channelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
              .channelInitializer { channel in
                  channel.pipeline.addHandler(TNConnectionHandler())
          }
          
      }
    
}
