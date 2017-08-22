//
//  Scenes.swift
//  Mac App
//
//  Created by Arthur Schiller on 22.08.17.
//

import SceneKit

class LeapVisualizationSceneManager: NSObject, SCNSceneRendererDelegate {
    let sceneView: SCNView
    let scene: LeapVisualizationScene
    
    var leapHandRepresentation: LeapHandRepresentation? = nil {
        didSet {
            guard let data = leapHandRepresentation else {
                return
            }
            scene.updateHand(with: data)
        }
    }
    
    init(sceneView: SCNView, scene: LeapVisualizationScene) {
        self.sceneView = sceneView
        self.scene = scene
        super.init()
        commonInit()
    }
    
    fileprivate func commonInit() {
        setupScene()
    }
    
    fileprivate func setupScene() {
        sceneView.scene = scene
        sceneView.backgroundColor = NSColor(red:0.17, green:0.17, blue:0.18, alpha:1.0)
        sceneView.autoenablesDefaultLighting = false
        sceneView.allowsCameraControl = true
        sceneView.showsStatistics = true
        sceneView.preferredFramesPerSecond = 60
        sceneView.antialiasingMode = .multisampling4X
        sceneView.delegate = self
    }
}

class LeapVisualizationScene: SCNScene {
    
    enum Mode {
        case showSkeleton
        case fingerPainting
        case moveAndRotate
    }
    
    var mode: Mode = .showSkeleton {
        didSet {
            updateMode()
        }
    }
    
    fileprivate var interactionBoxGeometry: SCNGeometry? {
        didSet {
            guard let geometry = interactionBoxGeometry else {
                return
            }
            interactionBoxNode.geometry = geometry
        }
    }
    
    fileprivate let cameraNode = SCNNode()
    fileprivate let interactionBoxNode: SCNNode = SCNNode()
    
    // Hand Visualization
    fileprivate lazy var geometryNode: SCNNode = {
        let geometry = SCNBox(width: 70, height: 2, length: 120, chamferRadius: 2)//SCNTorus(ringRadius: 20, pipeRadius: 2)
        geometry.firstMaterial?.diffuse.contents = NSColor.white.withAlphaComponent(0.8)
        let node = SCNNode(geometry: geometry)
        return node
    }()
    fileprivate lazy var handNode: LeapVisualizationHandNode = LeapVisualizationHandNode()
    
    // Particles
    fileprivate let particleNode = SCNNode()
    fileprivate lazy var particleTrail: SCNParticleSystem? = self.createTrail()
    
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
    
    fileprivate func commonInit() {
        setupCamera()
        setupHandNode()
        addGeometryNode()
        addParticleTrailNode()
        updateMode()
    }
    
    fileprivate func setupCamera() {
        let cameraNode = SCNNode()
        let camera = SCNCamera()
        camera.zFar = 1500
        cameraNode.camera = camera
        cameraNode.position = SCNVector3(x: 0, y: 400, z: 0)
        cameraNode.rotation = SCNVector4(x: 1, y: 0, z: 0, w: CGFloat(-90.degreesToRadians))
        rootNode.addChildNode(cameraNode)
    }
    
    fileprivate func setupHandNode() {
        rootNode.addChildNode(handNode)
    }
    
    fileprivate func addGeometryNode() {
        rootNode.addChildNode(geometryNode)
    }
    
    fileprivate func addParticleTrailNode() {
        guard let particleSystem = particleTrail else {
            return
        }
        particleNode.addParticleSystem(particleSystem)
        rootNode.addChildNode(particleNode)
    }
    
    fileprivate func createTrail() -> SCNParticleSystem? {
        guard let trail = SCNParticleSystem(named: "FireParticleTrail.scnp", inDirectory: nil) else {
            return nil
        }
        return trail
    }
    
    fileprivate func updateMode() {
        switch mode {
        case .showSkeleton:
            toggle(node: handNode, show: true)
            [particleNode, geometryNode].forEach { toggle(node: $0, show: false) }
        case .fingerPainting:
            toggle(node: particleNode, show: true)
            toggle(node: handNode, show: true)
            toggle(node: geometryNode, show: false)
        case .moveAndRotate:
            toggle(node: geometryNode, show: true)
            [particleNode, handNode].forEach { toggle(node: $0, show: false) }
        }
    }
}

extension LeapVisualizationScene {
    func updateInteractionBox(withData data: LeapInteractionBoxRepresentation) {
        interactionBoxGeometry = SCNBox(
            width: data.width,
            height: data.height,
            length: data.depth,
            chamferRadius: 0
        )
        interactionBoxGeometry?.firstMaterial?.diffuse.contents = NSColor.white.withAlphaComponent(0.2)
    }
    
    func updateHand(with data: LeapHandRepresentation) {
        switch mode {
        case .showSkeleton:
            handNode.update(with: data)
        case .fingerPainting:
            handNode.update(with: data)
            particleNode.position = data.fingers[1].tipPosition
        case .moveAndRotate:
            geometryNode.position = data.position
            geometryNode.eulerAngles = SCNVector3(
                x: data.eulerAngles.x,
                y: data.eulerAngles.y,
                z: data.eulerAngles.z
            )
        }
    }
    
    func toggleNodes(show: Bool) {
        let opacityAction = SCNAction.fadeOpacity(to: show ? 1 : 0, duration: 0.3)
        let nodes = [handNode, particleNode, geometryNode]
        nodes.forEach {
            $0.runAction(opacityAction)
        }
    }
    
    func toggle(node: SCNNode, show: Bool) {
        node.runAction(show ? SCNAction.unhide() : SCNAction.hide())
    }
}
