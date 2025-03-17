//
//  TNConnectionHandler.swift
//  Swift3270
//
//  Created by Rudi on 2025-03-17.
//

import Foundation
import NIO

class TNConnectionHandler: ChannelInboundHandler {
    typealias InboundIn = ByteBuffer
    typealias OutboundOut = ByteBuffer
    private var numBytes = 0
    
    // channel is connected, send a message
    func channelActive(ctx: ChannelHandlerContext) {
        let message = " "
        var buffer = ctx.channel.allocator.buffer(capacity: message.utf8.count)
        buffer.writeString(message)
        ctx.writeAndFlush(wrapOutboundOut(buffer), promise: nil)
    }
    
    func channelRead(ctx: ChannelHandlerContext, data: NIOAny) {
        var buffer = unwrapInboundIn(data)
        let readableBytes = buffer.readableBytes
        if let received = buffer.readString(length: readableBytes) {
            print(received)
        }
        if numBytes == 0 {
            print("nothing left to read, close the channel")
            ctx.close(promise: nil)
        }
    }
    
    
    func errorCaught(ctx: ChannelHandlerContext, error: Error) {
        print("error: \(error.localizedDescription)")
        ctx.close(promise: nil)
    }
}
