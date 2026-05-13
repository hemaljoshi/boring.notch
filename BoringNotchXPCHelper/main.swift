//
//  main.swift
//  BoringNotchXPCHelper
//
//  Created by Alexander on 2025-11-16.
//

import Foundation
import AppKit

/// Bundle identifier of the main app that is allowed to connect to this XPC service.
/// Only connections from this process are accepted; any other process is rejected.
private let allowedClientBundleID = "theboringteam.boringnotch"

class ServiceDelegate: NSObject, NSXPCListenerDelegate {
    
    /// This method is where the NSXPCListener configures, accepts, and resumes a new incoming NSXPCConnection.
    func listener(_ listener: NSXPCListener, shouldAcceptNewConnection newConnection: NSXPCConnection) -> Bool {
        
        // Validate that the connecting process is the main app (code signing identity).
        guard validateConnection(newConnection) else {
            newConnection.invalidate()
            return false
        }
        
        // Configure the connection.
        // First, set the interface that the exported object implements.
        newConnection.exportedInterface = NSXPCInterface(with: (any BoringNotchXPCHelperProtocol).self)
        
        // Next, set the object that the connection exports. All messages sent on the connection to this service will be sent to the exported object to handle. The connection retains the exported object.
        let exportedObject = BoringNotchXPCHelper()
        newConnection.exportedObject = exportedObject
        
        // Resuming the connection allows the system to deliver more incoming messages.
        newConnection.resume()
        
        // Returning true from this method tells the system that you have accepted this connection. If you want to reject the connection for some reason, call invalidate() on the connection and return false.
        return true
    }
    
    /// Validates the connecting process by checking that it is the main app (same bundle ID).
    /// Uses the connection's processIdentifier and NSRunningApplication to get the client's bundle ID.
    /// Only the main app (allowedClientBundleID) is accepted.
    private func validateConnection(_ connection: NSXPCConnection) -> Bool {
        let pid = connection.processIdentifier
        guard let app = NSRunningApplication(processIdentifier: pid) else {
            return false
        }
        guard let bundleID = app.bundleIdentifier else {
            return false
        }
        return bundleID == allowedClientBundleID
    }
}

// Create the delegate for the service.
let delegate = ServiceDelegate()

// Set up the one NSXPCListener for this service. It will handle all incoming connections.
let listener = NSXPCListener.service()
listener.delegate = delegate

// Require that the connecting process is signed with the main app's bundle ID (macOS 13+).
// Connections from any other process are rejected by the system before the delegate is called.
if #available(macOS 13.0, *) {
    listener.setConnectionCodeSigningRequirement("identifier \"\(allowedClientBundleID)\"")
}

// Resuming the serviceListener starts this service. This method does not return.
listener.resume()
