//
//  TN3270.swift
//  Swift3270
//
//  Created by Rudi on 2025-04-06.
//


import Network
import Foundation

class TN3270 {
   
    // --- Configuration ---
    var mainframeHost: NWEndpoint.Host = "10.31.93.1"
    var mainframePort: NWEndpoint.Port = 3270
    var terminalType = "IBM-3279-4-E"
    // --- End Configuration ---

    // --- Telnet Command Definitions ---
    // Basic Commands
    static let iac: UInt8 = 0xFF           // 255 - Interpret As Command
    static let sb: UInt8 = 0xFA            // 250 - Subnegotiation Begin
    static let se: UInt8 = 0xF0            // 240 - Subnegotiation End
    static let NOP: UInt8 = 0xF1           // 241 - No Operation
    static let dataMark: UInt8 = 0xF2      // 242 - The data stream portion of a Synch sequence
    static let breakCmd: UInt8 = 0xF3      // 243 - NVT character BRK
    static let interruptProc: UInt8 = 0xF4 // 244 - The function IP
    static let abortOutput: UInt8 = 0xF5   // 245 - The function AO
    static let areYouThere: UInt8 = 0xF6   // 246 - The function AYT
    static let eraseChar: UInt8 = 0xF7     // 247 - The function EC
    static let eraseLine: UInt8 = 0xF8     // 248 - The function EL
    static let goAhead: UInt8 = 0xF9       // 249 - The GA signal
    static let willCmd: UInt8 = 0xFB       // 251 - WILL option code
    static let wontCmd: UInt8 = 0xFC       // 252 - WON'T option code
    static let doCmd: UInt8 = 0xFD         // 253 - DO option code
    static let dontCmd: UInt8 = 0xFE       // 254 - DON'T option code

    // Telnet Option Codes
    static let transmitBinary: UInt8 = 0x00
    static let echo: UInt8 = 0x01
    static let suppressGoAhead: UInt8 = 0x03
    static let status: UInt8 = 0x05
    static let timingMark: UInt8 = 0x06
    static let terminalTypeOpt: UInt8 = 0x18
    static let endOfRecord: UInt8 = 0x19
    static let negotiateAboutWindowSize: UInt8 = 0x1f
    static let remoteFlowControl: UInt8 = 0x21
    static let linemode: UInt8 = 0x22
    static let newEnvironOption: UInt8 = 0x27

    // Subnegotiation Parameters for Terminal Type
    static let ttIs: UInt8 = 0x00
    static let ttSend: UInt8 = 0x01

    // Specific Sequences we handle
    var iacDoTerminalType = Data([iac, doCmd, terminalTypeOpt]) // FF FD 18
    var iacWillTerminalType = Data([iac, willCmd, terminalTypeOpt]) // FF FB 18

    var iacSbTerminalTypeSend = Data([iac, sb, terminalTypeOpt, ttSend, iac, se]) // FF FA 18 01 FF F0

    // Combined sequence reported by user for BINARY/EOR negotiation
    var serverBinaryEorNegotiation = Data([iac, doCmd, endOfRecord,   // FF FD 19 (DO EOR)
                                           iac, doCmd, transmitBinary, // FF FD 00 (DO BINARY)
                                           iac, willCmd, endOfRecord,  // FF FB 19 (WILL EOR)
                                           iac, willCmd, transmitBinary]) // FF FB 00 (WILL BINARY)

    // Our combined response for BINARY/EOR
    var clientBinaryEorResponse = Data([iac, willCmd, endOfRecord,    // FF FB 19 (WILL EOR)
                                        iac, willCmd, transmitBinary,  // FF FB 00 (WILL BINARY)
                                        iac, doCmd, endOfRecord,     // FF FD 19 (DO EOR)
                                        iac, doCmd, transmitBinary])   // FF FD 00 (DO BINARY)

    // --- End Telnet Definitions ---
    // The connection object
    var connection: NWConnection

    

    // Define a function to receive data in a loop
    func receiveLoop() {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 8192) { [self] (data, context, isComplete, error) in
            // Check for errors
            if let error = error {
                // Handle cancellation gracefully if it's intentional (e.g., user action)
                // In this example, any receive error is treated as fatal for simplicity.
                let nsError = error as NSError
                if !(nsError.code == POSIXError.ECANCELED.rawValue) {
                     print("❌ Error receiving data: \(error.localizedDescription)")
                } else {
                     print("ℹ️ Receive loop cancelled.") // Expected if connection.cancel() was called
                }
                connection.cancel()
                return // Stop the loop on error or cancellation
            }

            // Check if the connection is complete (closed by remote)
            if isComplete {
                print("🏁 Connection closed by remote host.")
                connection.cancel()
                return // Stop the loop if connection closed
            }

            // Process received data
            if let receivedData = data, !receivedData.isEmpty {
                var remainingData = receivedData // Work with a mutable copy to consume bytes

                // --- Telnet Command Parsing Loop ---
                // Keep processing as long as there's data and we find known Telnet commands at the start
                while !remainingData.isEmpty {
                    let currentBufferHex = remainingData.map { String(format: "%02hhX", $0) }.joined(separator: " ")
                    print("⬇️ Processing buffer (\(remainingData.count) bytes): \(currentBufferHex)")

                    // Check for known Telnet command sequences at the start of the current buffer
                    if remainingData.starts(with: iacDoTerminalType) { // FF FD 18
                        print("  ➡️ Detected IAC DO TERMINAL-TYPE.")
                        sendData(data: iacWillTerminalType, description: "IAC WILL TERMINAL-TYPE")
                        remainingData = remainingData.dropFirst(iacDoTerminalType.count)
                        continue // Continue checking the rest of the buffer in the while loop
                    }

                    if remainingData.starts(with: iacSbTerminalTypeSend) { // FF FA 18 01 FF F0
                        print("  ➡️ Detected IAC SB TERMINAL-TYPE SEND.")
                        // Construct the response: IAC SB TERMINAL-TYPE IS <type> IAC SE
                        guard let terminalTypeData = terminalType.data(using: .ascii) else {
                            print("❌ Error: Could not encode terminal type '\(terminalType)' to ASCII.")
                            connection.cancel() // Critical error
                            return
                        }
                        let response = Data([TN3270.iac, TN3270.sb, TN3270.terminalTypeOpt, TN3270.ttIs]) + terminalTypeData + Data([TN3270.iac, TN3270.se])
                        sendData(data: response, description: "IAC SB TERMINAL-TYPE IS \(terminalType)")
                        remainingData = remainingData.dropFirst(iacSbTerminalTypeSend.count)
                        continue // Continue checking the rest of the buffer
                    }

                    if remainingData.starts(with: serverBinaryEorNegotiation) { // FF FD 19 FF FD 00 FF FB 19 FF FB 00
                        print("  ➡️ Detected Server BINARY/EOR Negotiation sequence.")
                        sendData(data: clientBinaryEorResponse, description: "Client BINARY/EOR Response")
                        remainingData = remainingData.dropFirst(serverBinaryEorNegotiation.count)
                        continue // Continue checking the rest of the buffer
                    }

                    // *** Add other 'if remainingData.starts(with: ...)' checks here for other Telnet commands ***
                    // e.g., handle individual WILL/WONT/DO/DONT if needed

                    // If none of the above Telnet commands matched the start of the buffer,
                    // break out of the Telnet parsing loop for this received packet.
                    print("  ℹ️ No known Telnet command prefix found at start of remaining buffer.")
                    break // Exit the while loop

                } // --- End Telnet Command Parsing Loop ---


                // --- Handle leftover data (potential 3270 stream) ---
                if !remainingData.isEmpty {
                    let finalBufferHex = remainingData.map { String(format: "%02hhX", $0) }.joined(separator: " ")
                    print("  ✅ Assuming remaining data is 3270 Data Stream (\(remainingData.count) bytes).")
                    // --- Placeholder for 3270 Data Handling ---
                    // Here you would pass 'remainingData' to your EBCDIC decoder
                    // and 3270 command parser.
                    print("     Hex: \(finalBufferHex)")
                    // --- End Placeholder ---
                } else {
                     print("  ✅ Buffer fully processed (all Telnet commands handled).")
                }

            } else {
                 // No data received, but no error and not complete? Should not happen with minimumIncompleteLength: 1
                 print("  ⚠️ Received empty data without error or completion.")
            }

            // IMPORTANT: Schedule the next receive to continue the loop
            // Only schedule if connection is still active
            if connection.state == .ready {
                 receiveLoop()
            }
        }
    }


    // Define a helper function to send data
    func sendData(data: Data, description: String) {
        let hexString = data.map { String(format: "%02hhX", $0) }.joined(separator: " ")
        print("⬆️ Sending (\(data.count) bytes): \(description) - \(hexString)")

        connection.send(content: data, completion: .contentProcessed { (sendError) in
            if let error = sendError {
                print("❌ Error sending data (\(description)): \(error.localizedDescription)")
                // Consider cancelling the connection if sending fails critically
                // connection.cancel()
            } else {
                // Data sent successfully
                 // print("  ✅ Sent \(description) successfully.") // Optional: Can be verbose
            }
        })
    }



    // Initializes the TN3270 instance and establishes a connection.
    init(host: String, port: UInt16, model: String) {
        self.terminalType = model
        self.mainframeHost = NWEndpoint.Host(host)
        self.mainframePort = NWEndpoint.Port(integerLiteral: port)
        
        connection = NWConnection(host: mainframeHost, port: mainframePort, using: .tcp)
    }
    
    func startConnection() {
        // Define a handler for state updates (connecting, ready, failed, etc.)
        connection.stateUpdateHandler = { [self] (newState) in
            switch newState {
            case .ready:
                print("✅ Connection established to \(mainframeHost):\(mainframePort)")
                // Connection is ready, start the receive loop
                receiveLoop()
            case .failed(let error):
                print("❌ Connection failed: \(error.localizedDescription)")
                exit(EXIT_FAILURE) // Exit if connection fails
            case .waiting(let error):
                print("⏳ Waiting for network: \(error.localizedDescription)")
            case .setup:
                print("ℹ️ Setting up connection...")
            case .cancelled:
                print("🚫 Connection cancelled.")
                exit(EXIT_SUCCESS)
            case .preparing:
                print("ℹ️ Preparing connection...")
            @unknown default:
                fatalError("Unhandled connection state")
            }
        }
        connection.start(queue: .main)
    }

    // Ensures proper disconnection when the instance is deallocated.
    deinit {
        connection.cancel()
    }

  
}
