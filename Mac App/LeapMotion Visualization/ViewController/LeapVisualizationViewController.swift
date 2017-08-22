//
//  LeapMotionVisualizationViewController.swift
//  Mac App
//
//  Created by Arthur Schiller on 12.08.17.
//

import Cocoa
import SceneKit
import MultipeerConnectivity

class LeapVisualizationViewController: NSViewController {
    
    fileprivate var sceneManager: LeapVisualizationSceneManager?
    fileprivate let scene = LeapVisualizationScene()
    fileprivate lazy var sceneView: SCNView = {
        let view = SCNView(frame: .zero)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    // setup some properties for using multipeer connectivity
    fileprivate var peerID: MCPeerID!
    fileprivate var mcSession: MCSession!
    fileprivate var mcAdvertiserAssistant: MCAdvertiserAssistant!
    fileprivate var streamTargetPeer: MCPeerID?
    fileprivate var outputStream: OutputStream?
    
    fileprivate let leapService = LeapService()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        commonInit()
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        // as soon as the view appears, start advertising the service
        startHostingMCSession()
    }
    
    fileprivate func commonInit() {
        leapService.delegate = self
        leapService.run()
        
        sceneManager = LeapVisualizationSceneManager(
            sceneView: self.sceneView,
            scene: self.scene
        )
        
        view.addSubview(sceneView)
        NSLayoutConstraint.activate([
            sceneView.topAnchor.constraint(equalTo: view.topAnchor),
            sceneView.rightAnchor.constraint(equalTo: view.rightAnchor),
            sceneView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            sceneView.leftAnchor.constraint(equalTo: view.leftAnchor)
        ])
        
        setupMultipeerConnectivity()
        scene.toggleNodes(show: false)
    }
    
    fileprivate func setupMultipeerConnectivity() {
        setupPeerId()
        mcSession = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .none)
        mcSession.delegate = self
    }
    
    fileprivate func startHostingMCSession() {
        print("Start advertising.")
        mcAdvertiserAssistant = MCAdvertiserAssistant(
            serviceType: LMMCService.type,
            discoveryInfo: nil,
            session: mcSession
        )
        mcAdvertiserAssistant?.start()
    }
    
    fileprivate func setupPeerId() {
        
        /*
         If we have already have set a peerID, load it from the UserDefaults so we avoid creating a new one.
         Otherwise complications could arise. See:
         https://developer.apple.com/documentation/multipeerconnectivity/mcpeerid
         */
        
        let kDisplayNameKey = "kDisplayNameKey"
        let kPeerIDKey = "kPeerIDKey"
        let displayName: String = "LMDSupply"
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
    
    fileprivate func stream(data: LMHData) {
        guard let outputStream = outputStream else {
            print("No Stream available")
            return
        }
        
        outputStream.write(data.toBytes(), maxLength: 24)
    }
    
    fileprivate func startStream() {
        guard
            let streamTargetPeer = streamTargetPeer,
            let stream = try? mcSession.startStream(withName: "LMDataStream", toPeer: streamTargetPeer)
        else {
            return
        }
        
        stream.schedule(in: .main, forMode: .defaultRunLoopMode)
        stream.delegate = self
        stream.open()
        self.outputStream = stream
    }
}

extension LeapVisualizationViewController: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        switch state {
        case MCSessionState.connected:
            print("Connected: \(peerID.displayName)")
            streamTargetPeer = peerID
            startStream()
            
        case MCSessionState.connecting:
            print("Connecting: \(peerID.displayName)")
            
        case MCSessionState.notConnected:
            print("Not Connected: \(peerID.displayName)")
        }
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        print("did receive stream")
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        print("did start receiving resource")
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        print("did finish receiving resource")
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        print("did receive data")
    }
}

extension LeapVisualizationViewController: StreamDelegate {
    func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
        // handle stream
    }
}

extension LeapVisualizationViewController: LeapServiceDelegate {
    func willUpdateData() {
        scene.toggleNodes(show: true)
    }
    
    func didStopUpdatingData() {
        scene.toggleNodes(show: false)
    }
    
    func didUpdate(handRepresentation: LeapHandRepresentation) {
        sceneManager?.leapHandRepresentation = handRepresentation
        serializeAndStream(handData: handRepresentation)
    }
    
    private func serializeAndStream(handData: LeapHandRepresentation) {
        guard let translation = handData.translation else {
            return
        }
        let serializedData = LMHData(
            x: translation.x,
            y: translation.y,
            z: translation.z,
            pitch: handData.eulerAngles.x,
            yaw: handData.eulerAngles.y,
            roll: handData.eulerAngles.z
        )
        stream(data: serializedData)
    }
}
