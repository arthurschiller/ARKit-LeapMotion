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
    fileprivate let geometryNode: SCNNode = SCNNode()
    fileprivate let metalMaterial = MetalMaterial(surfaceType: .streaked)
    
    init(sceneView: ARSCNView) {
        self.sceneView = sceneView
        super.init()
        commonInit()
    }
    
    fileprivate func commonInit() {
        sceneView.scene = scene
        sceneView.autoenablesDefaultLighting = true
        sceneView.automaticallyUpdatesLighting = true
        sceneView.antialiasingMode = .multisampling4X
        sceneView.delegate = self
        sceneView.showsStatistics = true
        sceneView.debugOptions = [
//            ARSCNDebugOptions.showWorldOrigin,
            ARSCNDebugOptions.showFeaturePoints
        ]
        setupEnvironment()
        addGeometry()
    }
    
    private func addGeometry() {
        let boxGeometry = SCNBox(
            width: 0.2,
            height: 0.2,
            length: 0.2,
            chamferRadius: 0.005
        )
        boxGeometry.firstMaterial = metalMaterial
        geometryNode.geometry = boxGeometry
        geometryNode.position = SCNVector3(
            x: 0,
            y: 0,
            z: -0.5
        )
        scene.rootNode.addChildNode(geometryNode)
    }
    
    fileprivate func setupEnvironment() {
        let environmentMap = UIImage(named: "apartmentBlurred")
        scene.lightingEnvironment.contents = environmentMap
        scene.lightingEnvironment.intensity = 1.5
    }
    
    func updateGeometry(with translation: SCNVector3, and rotation: SCNVector3) {
        geometryNode.runAction(.move(by: translation, duration: 0))
        geometryNode.eulerAngles = rotation
    }
}

extension InteractiveARSceneManager {
    func runSession() {
        
        guard ARWorldTrackingConfiguration.isSupported else {
            let configuration = AROrientationTrackingConfiguration()
            sceneView.session.run(configuration)
            return
        }
        
        let configuration = ARWorldTrackingConfiguration()
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
