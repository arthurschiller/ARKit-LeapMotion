//
//  MPCBrowser.swift
//  iOS App
//
//  Created by Arthur Schiller on 19.08.17.
//

import Foundation
import MultipeerConnectivity

protocol LeapMotionMPCBrowserDelegate {
}

class LeapMotionMPCBrowser: NSObject {
    
    private let serviceType = "lm-data"
    
    private let localPeerId = MCPeerID(displayName: UIDevice.current.name)
    private let serviceBrowser: MCNearbyServiceBrowser
    
    var delegate: LeapMotionMPCBrowserDelegate?
    
    lazy var session: MCSession = {
        let session = MCSession(
            peer: self.localPeerId,
            securityIdentity: nil,
            encryptionPreference: .optional
        )
        session.delegate = self
        return session
    }()
    
    override init() {
        self.serviceBrowser = MCNearbyServiceBrowser(
            peer: localPeerId,
            serviceType: serviceType
        )
        super.init()
        self.serviceBrowser.delegate = self
        self.serviceBrowser.startBrowsingForPeers()
    }
    
    deinit {
        self.serviceBrowser.stopBrowsingForPeers()
    }
}

extension LeapMotionMPCBrowser: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        print("%@", "didNotStartBrowsingForPeers: \(error)")
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        print("%@", "foundPeer: \(peerID)")
        print("%@", "invitePeer: \(peerID)")
        browser.invitePeer(peerID, to: self.session, withContext: nil, timeout: 10)
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        print("%@", "lostPeer: \(peerID)")
    }

}

extension LeapMotionMPCBrowser: MCSessionDelegate {
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        print("%@", "peer \(peerID) didChangeState: \(state)")
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        print("%@", "didReceiveData: \(data)")
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        print("%@", "didReceiveStream")
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        print("%@", "didStartReceivingResourceWithName")
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        print("%@", "didFinishReceivingResourceWithName")
    }
    
    func session(_ session: MCSession, didReceiveCertificate certificate: [Any]?, fromPeer peerID: MCPeerID, certificateHandler: @escaping (Bool) -> Void) {
        certificateHandler(true)
    }
}


/*
class MPCBrowser: NSObject {
    
    lazy var serviceBrowser: MCNearbyServiceBrowser = MCNearbyServiceBrowser(peer: localPeerID, serviceType: serviceType)
    
    lazy var session: MCSession = {
        let session = MCSession(peer: localPeerID, securityIdentity: nil, encryptionPreference: .none)
        session.delegate = self
        return session
    }()
    
    let serviceType = "lms-mpc"
    let localPeerID = MCPeerID(displayName: UIDevice.current.name)
    
//    private var streamTargetPeer: MCPeerID?
//    private var outputStream: NSOutputStream?
    
    /*
    private func startStream() {
        guard let streamTargetPeer = streamTargetPeer where outputStream == nil else {
            return
        }
        do {
            outputStream = try session.startStreamWithName("LMDataStream", toPeer: streamTargetPeer)
            outputStream?.scheduleInRunLoop(.main, forMode: .defaultRunLoopMode)
            outputStream?.open()
        } catch {
            print("An error occured while trying to start the stream: \(error)")
        }
    }*/
}

extension MPCBrowser {
    func startBrowsing() {
        serviceBrowser.delegate = self
        serviceBrowser.startBrowsingForPeers()
    }
}

extension MPCBrowser: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        print("Found peer: \(peerID)")
//        streamTargetPeer = peerID
        browser.invitePeer(peerID, to: session, withContext: nil, timeout: 120)
    }
}

extension MPCBrowser: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        switch state {
        case .connected:
            print("Connected: \(peerID.displayName)")
            
        case .connecting:
            print("Connecting: \(peerID.displayName)")
            
        case .notConnected:
            print("Not Connected: \(peerID.displayName)")
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        
    }
    
    func session(_ session: MCSession, didReceiveCertificate certificate: [Any]?, fromPeer peerID: MCPeerID, certificateHandler: @escaping (Bool) -> Void) {
        
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        
    }
}*/
