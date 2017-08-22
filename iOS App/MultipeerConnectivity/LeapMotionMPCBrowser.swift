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
