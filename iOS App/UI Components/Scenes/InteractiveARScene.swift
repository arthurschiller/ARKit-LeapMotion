//
//  InteractiveARScene.swift
//  iOS App
//
//  Created by Arthur Schiller on 18.08.17.
//

import SceneKit

class InteractiveARScene: SCNScene {

    private let cameraNode = SCNNode()
    
    private lazy var geometryNode: SCNNode = {
        let geometry = SCNBox(width: 70, height: 2, length: 120, chamferRadius: 2)//SCNTorus(ringRadius: 20, pipeRadius: 2)
        geometry.firstMaterial?.diffuse.contents = UIColor.white.withAlphaComponent(0.8)
        let node = SCNNode(geometry: geometry)
        return node
    }()
    
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
        setupCamera()
        addGeometryNode()
    }
    
    private func setupCamera() {
        let cameraNode = SCNNode()
        let camera = SCNCamera()
        camera.zFar = 1500
        cameraNode.camera = camera
        cameraNode.position = SCNVector3(x: 0, y: 400, z: 0)
        cameraNode.rotation = SCNVector4(x: 1, y: 0, z: 0, w: Float(-90.degreesToRadians))
        rootNode.addChildNode(cameraNode)
    }

    private func addGeometryNode() {
        rootNode.addChildNode(geometryNode)
    }

    func updateGeometryPosition(with vector: SCNVector3) {
        geometryNode.position = vector
    }
    
    func updateGeometryEulerAngles(with vector: SCNVector3) {
        geometryNode.eulerAngles = vector
    }
}
