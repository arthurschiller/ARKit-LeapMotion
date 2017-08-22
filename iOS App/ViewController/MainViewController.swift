//
//  MainViewController.swift
//  iOS App
//
//  Created by Arthur Schiller on 19.08.17.
//

import UIKit
import ARKit
import MultipeerConnectivity

class MainViewController: UIViewController {
    
    // MARK: InterfaceBuilder Outlets
    @IBOutlet weak var arSceneView: ARSCNView!
    
    // MARK: Private properties
    fileprivate lazy var sceneManager: InteractiveARSceneManager = InteractiveARSceneManager(sceneView: self.arSceneView)
    fileprivate var peerID: MCPeerID!
    fileprivate var mcSession: MCSession!
    fileprivate var mcAdvertiserAssistant: MCAdvertiserAssistant!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        commonInit()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        sceneManager.runSession()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneManager.pauseSession()
    }

    private func commonInit() {
        setupMultipeerConnectivity()
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(viewWasTapped))
        view.addGestureRecognizer(tapGestureRecognizer)
    }
    
    @objc private func viewWasTapped() {
        joinMCSession()
    }
    
    private func setupMultipeerConnectivity() {
        setupPeerId()
        mcSession = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .none)
        mcSession.delegate = self
    }
    
    private func joinMCSession() {
        let mcBrowser = MCBrowserViewController(serviceType: LMMCService.type, session: mcSession)
        mcBrowser.delegate = self
        mcBrowser.modalPresentationStyle = .overCurrentContext
        mcBrowser.modalTransitionStyle = .crossDissolve
        present(mcBrowser, animated: true, completion: nil)
    }
    
    private func setupPeerId() {
        let kDisplayNameKey = "kDisplayNameKey"
        let kPeerIDKey = "kPeerIDKey"
        let displayName: String = "LMDUser"
        let defaults = UserDefaults.standard
        let oldDisplayName = defaults.string(forKey: kDisplayNameKey)
        
        if oldDisplayName == displayName {
            guard let peerIDData = defaults.data(forKey: kPeerIDKey) else {
                return
            }
            guard let id = NSKeyedUnarchiver.unarchiveObject(with: peerIDData) as? MCPeerID else {
                return
            }
            self.peerID = id
            return
        }
        
        let peerID = MCPeerID(displayName: displayName)
        let peerIDData = NSKeyedArchiver.archivedData(withRootObject: peerID)
        defaults.set(peerIDData, forKey: kPeerIDKey)
        defaults.set(displayName, forKey: kDisplayNameKey)
        defaults.synchronize()
        self.peerID = peerID
    }
}

extension MainViewController: MCSessionDelegate, MCBrowserViewControllerDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        switch state {
        case MCSessionState.connected:
            print("Connected: \(peerID.displayName)")
//            valueLabel.text = "Connected: \(peerID.displayName)"
            
        case MCSessionState.connecting:
            print("Connecting: \(peerID.displayName)")
            
        case MCSessionState.notConnected:
            print("Not Connected: \(peerID.displayName)")
        }
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        print("received stream")
        stream.delegate = self
        stream.schedule(in: .main, forMode: .defaultRunLoopMode)
        stream.open()
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        print("%@", "didReceiveData: \(data)")
    }
    
    func browserViewControllerDidFinish(_ browserViewController: MCBrowserViewController) {
        browserViewController.dismiss(animated: true, completion: nil)
    }
    
    func browserViewControllerWasCancelled(_ browserViewController: MCBrowserViewController) {
        browserViewController.dismiss(animated: true, completion: nil)
    }
}

extension MainViewController: StreamDelegate {
    func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
        print("handle stream")
        
        guard
            let inputStream = aStream as? InputStream,
            eventCode == .hasBytesAvailable
        else {
                return
        }
        var bytes = [UInt8](repeating: 0, count: 24)
        inputStream.read(&bytes, maxLength: 24)
        
        let handData = LMHData(fromBytes: bytes)
        
        DispatchQueue.main.async {
            let translation = SCNVector3(
                x: handData.x * 0.01,
                y: handData.y * 0.01,
                z: handData.z * 0.01
            )
            let rotation = SCNVector3(
                x: handData.yaw,
                y: handData.roll,
                z: handData.pitch
            )
            self.sceneManager.updateGeometry(with: translation, and: rotation)
        }
    }
}

