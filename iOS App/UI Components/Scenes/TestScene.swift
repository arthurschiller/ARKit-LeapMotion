//
//  InteractiveARScene.swift
//  iOS App
//
//  Created by Arthur Schiller on 18.08.17.
//

import SceneKit

class TestScene: SCNScene {

    private let cameraNode = SCNNode()
    private let metalMaterial = MetalMaterial(surfaceType: .streaked)
    
    private lazy var geometryNode: SCNNode = {
        let geometry = SCNBox(width: 0.2, height: 0.2, length: 0.2, chamferRadius: 0.001)//SCNTorus(ringRadius: 0.2, pipeRadius: 0.05)//
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
        setupEnvironment()
        setupGeometryNode()
    }
    
    private func setupEnvironment() {
        let environmentMap = UIImage(named: "apartmentBlurred")
        background.contents = environmentMap
        
        lightingEnvironment.contents = environmentMap
        lightingEnvironment.intensity = 1.5
    }
    
    private func setupCamera() {
        let cameraNode = SCNNode()
        let camera = SCNCamera()
        camera.zFar = 1500
        camera.zNear = 0.1
        cameraNode.camera = camera
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 2)
        rootNode.addChildNode(cameraNode)
    }

    private func setupGeometryNode() {
        rootNode.addChildNode(geometryNode)
        geometryNode.geometry?.firstMaterial = metalMaterial
    }

    func updateGeometryPosition(with vector: SCNVector3) {
        geometryNode.runAction(.move(by: vector, duration: 0.01))
    }
    
    func updateGeometryEulerAngles(with vector: SCNVector3) {
        geometryNode.eulerAngles = vector
    }
}
