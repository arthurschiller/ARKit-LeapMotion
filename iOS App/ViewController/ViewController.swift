//
//  ViewController.swift
//  iOS App
//
//  Created by Arthur Schiller on 28.07.17.
//

import UIKit
import SceneKit
import MultipeerConnectivity

class ViewController: UIViewController {
    
    @IBOutlet weak var connection: UILabel!
    @IBOutlet weak var valueLabel: UILabel!
    
//    fileprivate let central: LeapMotionGestureCentral = LeapMotionGestureCentral()
//    fileprivate let jsonDecoder = JSONDecoder()
    
    private var peerID: MCPeerID!
    private var mcSession: MCSession!
    private var mcAdvertiserAssistant: MCAdvertiserAssistant!
    
    fileprivate let sceneView = SCNView()
    fileprivate let interactiveARScene = InteractiveARScene()
    
    fileprivate let backgroundQueue = DispatchQueue(
        label: "com.arthurschiller.backgroundQueue",
        qos: DispatchQoS.userInitiated
    )

    override func viewDidLoad() {
        super.viewDidLoad()
        commonInit()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        joinMCSession()
    }
    
    private func commonInit() {
        valueLabel.text = ""
//        central.delegate = self
        setupScene()
        setupMultipeerConnectivity()
    }
    
    private func setupScene() {
        sceneView.translatesAutoresizingMaskIntoConstraints = false
        view.insertSubview(sceneView, at: 0)
        NSLayoutConstraint.activate(
            [
                sceneView.topAnchor.constraint(equalTo: view.topAnchor),
                sceneView.rightAnchor.constraint(equalTo: view.rightAnchor),
                sceneView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                sceneView.leftAnchor.constraint(equalTo: view.leftAnchor)
            ]
        )
        
        sceneView.scene = interactiveARScene
        sceneView.backgroundColor = .cyan
        sceneView.autoenablesDefaultLighting = true
        sceneView.allowsCameraControl = true
        sceneView.showsStatistics = true
        sceneView.preferredFramesPerSecond = 60
        sceneView.antialiasingMode = .multisampling4X
    }
    
    private func setupMultipeerConnectivity() {
        setupPeerId()
        mcSession = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .none)
        mcSession.delegate = self
    }
    
    private func handle(handDataString: String) {
        backgroundQueue.async {
            let floatValues = handDataString.components(separatedBy: ",")
                .flatMap {
                    ($0 as NSString).floatValue
            }
            guard floatValues.count == 3 else {
                print("Received unexpected data.")
                return
            }
            
            DispatchQueue.main.sync {
                self.interactiveARScene.updateGeometryPosition(with:
                    SCNVector3(
                        x: floatValues[0],
                        y: floatValues[1],
                        z: floatValues[2]
                    )
                )
            }
        }
    }
    
    private func startHostingMCSession() {
        print("Start advertising.")
        mcAdvertiserAssistant = MCAdvertiserAssistant(
            serviceType: LMMCService.type,
            discoveryInfo: nil,
            session: mcSession
        )
        mcAdvertiserAssistant?.start()
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

extension ViewController: MCSessionDelegate, MCBrowserViewControllerDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        switch state {
        case MCSessionState.connected:
            print("Connected: \(peerID.displayName)")
            
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
        guard let string = String(data: data, encoding: .utf8) else {
            return
        }
        DispatchQueue.main.async {
            self.connection.text = string
        }
    }
    
    func browserViewControllerDidFinish(_ browserViewController: MCBrowserViewController) {
        browserViewController.dismiss(animated: true, completion: nil)
    }
    
    func browserViewControllerWasCancelled(_ browserViewController: MCBrowserViewController) {
        browserViewController.dismiss(animated: true, completion: nil)
    }
}

extension ViewController: StreamDelegate {
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
            print(handData)
            self.interactiveARScene.updateGeometryPosition(with:
                SCNVector3(
                    x: handData.x,
                    y: handData.y,
                    z: handData.z
                )
            )
            self.interactiveARScene.updateGeometryEulerAngles(with:
                SCNVector3(
                    x: handData.pitch,
                    y: handData.yaw,
                    z: handData.roll
                )
            )
        }
    }
}

extension ViewController: LeapMotionGestureCentralDelegate {
    func central(_ central: LeapMotionGestureCentral, didPerformAction action: LeapMotionGestureCentral.Action) {
        switch action {
        case .read(let value):
            handle(value: value)
        case .connectPeripheral(_):
            connection.text = "connected"
        case .disconnectPeripheral:
            connection.text = "disconnected"
        }
    }
    
    private func handle(value: LeapMotionGestureCentral.Value) {
        switch value {
        case .handData(let string):
            connection.text = string
            handle(handDataString: string)
        }
    }
}
