//
//  InteractiveARSceneManager.swift
//  iOS App
//
//  Created by Arthur Schiller on 19.08.17.
//

import UIKit
import ARKit

class InteractiveARSceneManager: NSObject {
    fileprivate let sceneView: ARSCNView
    fileprivate let scene = SCNScene()
    fileprivate var planes: [String : SCNNode] = [:]
    fileprivate var showPlanes: Bool = true
    
    init(sceneView: ARSCNView) {
        self.sceneView = sceneView
        super.init()
        commonInit()
    }
    
    private func commonInit() {
        sceneView.scene = scene
        sceneView.autoenablesDefaultLighting = true
        sceneView.antialiasingMode = .multisampling4X
        sceneView.delegate = self
        sceneView.showsStatistics = true
        sceneView.debugOptions = [
            ARSCNDebugOptions.showWorldOrigin,
            ARSCNDebugOptions.showFeaturePoints
        ]
        addGeometry()
    }
    
    private func addGeometry() {
        let boxGeometry = SCNBox(
            width: 0.2,
            height: 0.2,
            length: 0.2,
            chamferRadius: 0
        )
        let boxNode = SCNNode(geometry: boxGeometry)
        boxNode.position = SCNVector3(
            x: 0,
            y: 0,
            z: -0.5
        )
        scene.rootNode.addChildNode(boxNode)
    }
}

extension InteractiveARSceneManager {
    func runSession() {
        
        guard ARWorldTrackingSessionConfiguration.isSupported else {
            let configuration = ARSessionConfiguration()
            sceneView.session.run(configuration)
            return
        }
        
        let configuration = ARWorldTrackingSessionConfiguration()
        configuration.planeDetection = .horizontal
        sceneView.session.run(
            configuration,
            options: [
                .resetTracking,
                .removeExistingAnchors
            ]
        )
    }
    
    func pauseSession() {
        sceneView.session.pause()
    }
}

extension InteractiveARSceneManager: ARSCNViewDelegate {
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        
        let key = planeAnchor.identifier.uuidString
        let planeNode = NodeGenerator.generatePlaneFrom(planeAnchor: planeAnchor, physics: true, hidden: !self.showPlanes)
        node.addChildNode(planeNode)
        self.planes[key] = planeNode
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        
        let key = planeAnchor.identifier.uuidString
        if let existingPlane = self.planes[key] {
            NodeGenerator.update(planeNode: existingPlane, from: planeAnchor, hidden: !self.showPlanes)
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        
        let key = planeAnchor.identifier.uuidString
        if let existingPlane = self.planes[key] {
            existingPlane.removeFromParentNode()
            self.planes.removeValue(forKey: key)
        }
    }
}

class Plane: SCNNode {
    
    let anchor: ARPlaneAnchor
    private var planeGeometry: SCNPlane? = nil
    
    init(with anchor: ARPlaneAnchor) {
        self.anchor = anchor
        super.init()
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func commonInit() {
        let geometry = SCNPlane(
            width: CGFloat(anchor.extent.x),
            height: CGFloat(anchor.extent.z)
        )
        geometry.firstMaterial?.diffuse.contents = UIColor.cyan
        self.planeGeometry = geometry
        let planeNode = SCNNode(geometry: geometry)
        planeNode.position = SCNVector3(
            x: anchor.center.x,
            y: 0,
            z: anchor.center.z
        )
        planeNode.transform = SCNMatrix4MakeRotation(Float.pi / 2, 1, 0, 0)
        addChildNode(planeNode)
    }
    
    func update(anchor: ARPlaneAnchor) {
        planeGeometry?.width = CGFloat(anchor.extent.x)
        planeGeometry?.height = CGFloat(anchor.extent.z)
        position = SCNVector3(
            x: anchor.center.x,
            y: 0,
            z: anchor.center.z
        )
    }
}
