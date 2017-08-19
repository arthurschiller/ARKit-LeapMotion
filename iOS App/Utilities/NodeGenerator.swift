//
//  NodeGenerator.swift
//  iOS App
//
//  Created by Arthur Schiller on 19.08.17.
//
// adapted from: https://github.com/CapTechMobile/arkit-demo/blob/master/arkit-demo/Utilities/NodeGenerator.swift

import Foundation
import SceneKit
import ARKit

struct NodeGenerator {
    
//    static func generateSphereInFrontOf(node: SCNNode) -> SCNNode {
//        let radius = (0.02...0.06).random()
//        let sphere = SCNSphere(radius: CGFloat(radius))
//
//        let color = SCNMaterial()
//        color.diffuse.contents = self.randomColor()
//        sphere.materials = [color]
//
//        let sphereNode = SCNNode(geometry: sphere)
//
//        let position = SCNVector3(x: 0, y: 0, z: -1)
//        sphereNode.position = node.convertPosition(position, to: nil)
//        sphereNode.rotation = node.rotation
//
//        return sphereNode
//    }
//
//    static func generateCubeInFrontOf(node: SCNNode, physics: Bool) -> SCNNode {
//        let size = CGFloat((0.06...0.1).random())
//        let box = SCNBox(width: size, height: size, length: size, chamferRadius: 0)
//
//        let color = SCNMaterial()
//        color.diffuse.contents = self.randomColor()
//        box.materials = [color]
//
//        let boxNode = SCNNode(geometry: box)
//
//        let position = SCNVector3(x: 0, y: 0, z: -1)
//        boxNode.position = node.convertPosition(position, to: nil)
//        boxNode.rotation = node.rotation
//
//        if physics {
//            let physicsBody = SCNPhysicsBody(type: .dynamic, shape: SCNPhysicsShape(geometry: box, options: nil))
//            physicsBody.mass = 1.25
//            physicsBody.restitution = 0.25
//            physicsBody.friction = 0.75
//            physicsBody.categoryBitMask = CollisionTypes.shape.rawValue
//            boxNode.physicsBody = physicsBody
//        }
//
//        return boxNode
//    }
    
    static func generatePlaneFrom(planeAnchor: ARPlaneAnchor, physics: Bool, hidden: Bool) -> SCNNode {
        let plane = self.plane(from: planeAnchor, hidden: hidden)
        
        let planeNode = SCNNode(geometry: plane)
        planeNode.position = self.position(from: planeAnchor)
        
        if physics {
            let body = SCNPhysicsBody(type: .kinematic, shape: SCNPhysicsShape(geometry: plane, options: nil))
            body.restitution = 0.0
            body.friction = 1.0
            planeNode.physicsBody = body
        }
        
        return planeNode
    }
    
    static func update(planeNode: SCNNode, from planeAnchor: ARPlaneAnchor, hidden: Bool) {
        planeNode.geometry = self.plane(from: planeAnchor, hidden: hidden)
        planeNode.position = self.position(from: planeAnchor)
    }
    
    static func update(planeNode: SCNNode, hidden: Bool) {
        planeNode.geometry?.materials.first?.diffuse.contents = hidden ? UIColor(white: 1, alpha: 0) : UIColor(red: 0, green: 0, blue: 1, alpha: 0.5)
    }
    
    private static func plane(from planeAnchor: ARPlaneAnchor, hidden: Bool) -> SCNGeometry {
        let plane = SCNBox(width: CGFloat(planeAnchor.extent.x), height: 0.005, length: CGFloat(planeAnchor.extent.z), chamferRadius: 0)
        
        let color = SCNMaterial()
        color.diffuse.contents = hidden ? UIColor(white: 1, alpha: 0) : UIColor(red: 0, green: 0, blue: 1, alpha: 0.5)
        plane.materials = [color]
        
        return plane
    }
    
    private static func position(from planeAnchor: ARPlaneAnchor) -> SCNVector3 {
        return SCNVector3Make(planeAnchor.center.x, -0.005, planeAnchor.center.z)
    }
}

extension ClosedRange where Bound : FloatingPoint {
    public func random() -> Bound {
        let range = self.upperBound - self.lowerBound
        let randomValue = (Bound(arc4random_uniform(UINT32_MAX)) / Bound(UINT32_MAX)) * range + self.lowerBound
        return randomValue
    }
}

struct CollisionTypes: OptionSet {
    let rawValue: Int
    
    static let bottom  = CollisionTypes(rawValue: 1 << 0)
    static let shape = CollisionTypes(rawValue: 1 << 1)
}
