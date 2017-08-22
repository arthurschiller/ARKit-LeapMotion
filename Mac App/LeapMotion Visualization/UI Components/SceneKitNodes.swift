//
//  SceneKitNodes.swift
//  Mac App
//
//  Created by Arthur Schiller on 22.08.17.
//

import SceneKit

class LeapVisualizationHandNode: SCNNode {
    
    private let connectionLineNode = SCNNode()
    private lazy var thumb = LeapVisualizationFingerNode(type: .thumb)
    private lazy var indexFinger = LeapVisualizationFingerNode(type: .index)
    private lazy var middleFinger = LeapVisualizationFingerNode(type: .middle)
    private lazy var ringFinger = LeapVisualizationFingerNode(type: .ring)
    private lazy var pinkyFinger = LeapVisualizationFingerNode(type: .pinky)
    
    private lazy var fingers: [LeapVisualizationFingerNode] = [
        self.thumb,
        self.indexFinger,
        self.middleFinger,
        self.ringFinger,
        self.pinkyFinger
    ]
    
    override init() {
        super.init()
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        commonInit()
    }
    
    private func commonInit() {
        addChildNode(connectionLineNode)
        fingers.forEach {
            addChildNode($0)
        }
    }
    
    func update(with data: LeapHandRepresentation) {
        guard data.fingers.count == 5 else {
            return
        }
        for i in 0...fingers.count - 1 {
            fingers[i].update(with: data.fingers[i])
        }
        connectionLineNode.geometry = SCNGeometry.makeLine(
            from: data.fingers[0].mcpPosition,
            connectedTo: [
                data.fingers[1].mcpPosition,
                data.fingers[2].mcpPosition,
                data.fingers[3].mcpPosition,
                data.fingers[4].mcpPosition
            ]
        )
    }
}

class LeapVisualizationFingerNode: SCNNode {
    
    let type: LeapFingerType
    
    private lazy var mcpJoint: SCNNode = self.makeJoint()
    private lazy var pipJoint: SCNNode = self.makeJoint()
    private lazy var dipJoint: SCNNode = self.makeJoint()
    private lazy var tipJoint: SCNNode = self.makeJoint()
    
    private let boneLine = SCNNode()
    
    private lazy var joints: [SCNNode] = [
        self.mcpJoint,
        self.pipJoint,
        self.dipJoint,
        self.tipJoint
    ]
    
    init(type: LeapFingerType) {
        self.type = type
        super.init()
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        commonInit()
    }
    
    private func commonInit() {
        addChildNode(boneLine)
        
        joints.forEach {
            addChildNode($0)
        }
    }
    
    private func makeJoint() -> SCNNode {
        let geometry = SCNSphere(radius: 2)
        return SCNNode(geometry: geometry)
    }
    
    func update(with data: LeapFingerRepresentation) {
        boneLine.geometry = SCNGeometry.makeLine(from:
            [
                data.mcpPosition,
                data.pipPosition,
                data.dipPosition,
                data.tipPosition
            ]
        )
        mcpJoint.position = data.mcpPosition
        pipJoint.position = data.pipPosition
        dipJoint.position = data.dipPosition
        tipJoint.position = data.tipPosition
    }
}

extension SCNGeometry {
    class func makeLine(from startPoint: SCNVector3, to endPoint: SCNVector3) -> SCNGeometry {
        let indices: [Int32] = [0, 1]
        let source = SCNGeometrySource(vertices: [startPoint, endPoint])
        let element = SCNGeometryElement(indices: indices, primitiveType: .line)
        return SCNGeometry(sources: [source], elements: [element])
    }
    
    class func makeLine(from points: [SCNVector3]) -> SCNGeometry? {
        guard !points.isEmpty || points.count == 1 else {
            return nil
        }
        var indices: [Int32] = [0]
        if points.count > 2 {
            for i in 1...points.count - 2 {
                indices.append(Int32(i))
                indices.append(Int32(i))
            }
        }
        indices.append(Int32((points.count - 1)))
        let source = SCNGeometrySource(vertices: points)
        let element = SCNGeometryElement(indices: indices, primitiveType: SCNGeometryPrimitiveType.line)
        return SCNGeometry(sources: [source], elements: [element])
    }
    
    class func makeLine(from startPoint: SCNVector3, connectedTo endPoints: [SCNVector3]) -> SCNGeometry {
        var indices: [Int32] = []
        for i in 0...endPoints.count {
            indices.append(0)
            indices.append(Int32(i))
        }
        var points = endPoints
        points.insert(startPoint, at: 0)
        let source = SCNGeometrySource(vertices: points)
        let element = SCNGeometryElement(indices: indices, primitiveType: SCNGeometryPrimitiveType.line)
        return SCNGeometry(sources: [source], elements: [element])
    }
}
