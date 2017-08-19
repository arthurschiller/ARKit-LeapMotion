//
//  LeapMotionVisualizationViewController.swift
//  Mac App
//
//  Created by Arthur Schiller on 12.08.17.
//

import Cocoa
import SceneKit
import OpenGL

class LeapVisualizationViewController: NSViewController {
    
    private var sceneManager: LeapVisualizationSceneManager?
    private let scene = LeapVisualizationScene()
    private lazy var sceneView: SCNView = {
        let view = SCNView(frame: .zero)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let leapMotionGesturePeripheral = LeapMotionGesturePeripheral()
    private let leapService = LeapService()
    private let jsonEncoder = JSONEncoder()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        commonInit()
    }
    
    private func commonInit() {
        leapMotionGesturePeripheral.startAdvertising()
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
    }
    
//    private func prepareAndAdvertisePeripheralData(with handRepresentation: LeapHandRepresentation) {
////        let dataString = "\(handRepresentation.position.x),\(handRepresentation.position.y),\(handRepresentation.position.z),\(handRepresentation.eulerAngles.x),\(handRepresentation.eulerAngles.y),\(handRepresentation.eulerAngles.z)"
////        let dataString = "\(handRepresentation.position.x),\(handRepresentation.position.y),\(handRepresentation.position.z)"
////        leapMotionGesturePeripheral.set(handDataString: dataString)
//    }
}

extension LeapVisualizationViewController: LeapServiceDelegate {
    func willUpdateData() {
        scene.toggleNodes(show: true)
    }
    
    func didStopUpdatingData() {
        scene.toggleNodes(show: false)
    }
    
    func didUpdate(interactionBoxRepresentation: LeapInteractionBoxRepresentation) {
        print("interaction box did change")
//        scene.updateInteractionBox(withData: interactionBoxData)
    }
    
    func didUpdate(handRepresentation: LeapHandRepresentation) {
        sceneManager?.leapHandRepresentation = handRepresentation
    }
    
    func didUpdate(handDataString: String) {
        leapMotionGesturePeripheral.set(handDataString: handDataString)
    }
}

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
    
    private func commonInit() {
        setupScene()
    }
    
    private func setupScene() {
        sceneView.scene = scene
        sceneView.backgroundColor = .cyan
        sceneView.autoenablesDefaultLighting = false
        sceneView.allowsCameraControl = true
        sceneView.showsStatistics = true
        sceneView.preferredFramesPerSecond = 60
        sceneView.antialiasingMode = .multisampling4X
        sceneView.delegate = self
    }
    
    func renderer(_ renderer: SCNSceneRenderer, willRenderScene scene: SCNScene, atTime time: TimeInterval) {
        // hook into rendering
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
    
    private var interactionBoxGeometry: SCNGeometry? {
        didSet {
            guard let geometry = interactionBoxGeometry else {
                return
            }
            interactionBoxNode.geometry = geometry
        }
    }
    
    private let cameraNode = SCNNode()
    private let interactionBoxNode: SCNNode = SCNNode()
    
    private lazy var geometryNode: SCNNode = {
        let geometry = SCNBox(width: 70, height: 2, length: 120, chamferRadius: 2)//SCNTorus(ringRadius: 20, pipeRadius: 2)
        geometry.firstMaterial?.diffuse.contents = NSColor.white.withAlphaComponent(0.8)
        let node = SCNNode(geometry: geometry)
        return node
    }()
    private lazy var handNode: LeapVisualizationHandNode = LeapVisualizationHandNode()
    private let particleNode = SCNNode()
    private lazy var particleTrail: SCNParticleSystem? = self.createTrail()
    
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
        setupHandNode()
        addGeometryNode()
        addParticleTrailNode()
        updateMode()
        
//        delay(withSecond: 3) {
//            self.mode = .fingerPainting
//        }
//
//        delay(withSecond: 6) {
//            self.mode = .moveAndRotate
//        }
    }
    
    private func setupCamera() {
        let cameraNode = SCNNode()
        let camera = SCNCamera()
        camera.zFar = 1500
        cameraNode.camera = camera
        cameraNode.position = SCNVector3(x: 0, y: 400, z: 0)
        cameraNode.rotation = SCNVector4(x: 1, y: 0, z: 0, w: CGFloat(-90.degreesToRadians))
        rootNode.addChildNode(cameraNode)
    }
    
    private func setupHandNode() {
        rootNode.addChildNode(handNode)
    }
    
    private func addGeometryNode() {
        rootNode.addChildNode(geometryNode)
    }
    
    private func addParticleTrailNode() {
        guard let particleSystem = particleTrail else {
            return
        }
        particleNode.addParticleSystem(particleSystem)
        rootNode.addChildNode(particleNode)
    }
    
    private func createTrail() -> SCNParticleSystem? {
        guard let trail = SCNParticleSystem(named: "FireParticleTrail.scnp", inDirectory: nil) else {
            return nil
        }
        return trail
    }
    
    private func updateMode() {
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
