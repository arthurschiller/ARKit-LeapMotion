//
//  LeapMotionVisualizationViewController.swift
//  Mac App
//
//  Created by Arthur Schiller on 12.08.17.
//

import Cocoa
import SceneKit

class LeapVisualizationViewController: NSViewController {
    
    private let scene = LeapVisualizationScene()
    private lazy var sceneView: SCNView = {
        let scene = SCNView(frame: .zero)
        scene.translatesAutoresizingMaskIntoConstraints = false
        return scene
    }()
    
    let leapMotionGesturePeripheral = LeapMotionGesturePeripheral()
    var leapService: LeapService?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        commonInit()
    }
    
    @objc private func didPan(sender: NSPanGestureRecognizer) {
        if sender.state == .ended {
            guard
                let quaternion = self.sceneView.pointOfView?.orientation,
                let position = self.sceneView.pointOfView?.position
                else {
                    return
            }
            print("Orientation: (\(quaternion.x),\(quaternion.y),\(quaternion.z),\(quaternion.w)) Position: (\(position.x),\(position.y),\(position.z)")
        }
    }
    
    private func commonInit() {
//        leapMotionGesturePeripheral.startAdvertising()
        
        leapService = LeapService()
        leapService?.delegate = self
        leapService?.run()
        
        setupScene()
        
        let gestureRecognizer = NSPanGestureRecognizer(target: self, action: #selector(didPan))
        gestureRecognizer.delaysPrimaryMouseButtonEvents = false
        gestureRecognizer.delaysSecondaryMouseButtonEvents = false
        sceneView.addGestureRecognizer(gestureRecognizer)
        view.addSubview(sceneView)
        NSLayoutConstraint.activate([
            sceneView.topAnchor.constraint(equalTo: view.topAnchor),
            sceneView.rightAnchor.constraint(equalTo: view.rightAnchor),
            sceneView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            sceneView.leftAnchor.constraint(equalTo: view.leftAnchor)
        ])
    }
    
    private func setupScene() {
        sceneView.scene = scene
        sceneView.backgroundColor = .black
        sceneView.autoenablesDefaultLighting = true
        sceneView.allowsCameraControl = true
        sceneView.showsStatistics = true
        sceneView.preferredFramesPerSecond = 60
    }
    
    override func touchesEnded(with event: NSEvent) {
        super.touchesEnded(with: event)
        print("touch")
    }
    
    override func mouseDragged(with event: NSEvent) {
        super.mouseDragged(with: event)
        print("yup")
    }
}

extension LeapVisualizationViewController: LeapServiceDelegate {
    func didUpdate(interactionBoxRepresentation: LeapInteractionBoxRepresentation) {
        print("interaction box did change")
//        scene.updateInteractionBox(withData: interactionBoxData)
    }
    
    func didUpdate(handRepresentation: LeapHandRepresentation) {
        scene.updateHand(with: handRepresentation)
    }
}

class LeapVisualizationScene: SCNScene {
    private var interactionBoxGeometry: SCNGeometry? {
        didSet {
            guard let geometry = interactionBoxGeometry else {
                return
            }
            interactionBoxNode.geometry = geometry
        }
    }
    
    private let cameraNode = SCNNode()
    private let floorNode: SCNNode = SCNNode()
    private let interactionBoxNode: SCNNode = SCNNode()
    private lazy var handNode: LeapVisualizationHandNode = LeapVisualizationHandNode()
    
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
//        rootNode.addChildNode(cameraNode)
//        setupCamera()
        let box = SCNNode(geometry: SCNBox(width: 50, height: 4, length: 50, chamferRadius: 0))
        box.geometry?.firstMaterial?.diffuse.contents = NSColor.white.withAlphaComponent(0)
//        rootNode.addChildNode(interactionBoxNode)
//        floorNode.geometry = SCNFloor()
        floorNode.position.y = -10
        floorNode.position.z = 10
//        floorNode.position = SCNVector3Zero
//        floorNode.geometry?.firstMaterial?.diffuse.contents = NSColor.white.withAlphaComponent(0.8)
//        rootNode.addChildNode(floorNode)
        rootNode.addChildNode(box)
        rootNode.addChildNode(handNode)
    }
    
    private func setupCamera() {
        let camera = SCNCamera()
        camera.xFov = 40
        camera.yFov = 40
        cameraNode.camera = camera
        
//        (-0.659327924251556,0.00110108347143978,-0.00492901774123311,0.751838564872742) Position: (3.4608268737793,420.715454101562,55.4095077514648
        
        cameraNode.position = SCNVector3(
            x: 3.4608268737793,
            y: 420.715454101562,
            z: 55.4095077514648
        )
        
        cameraNode.orientation = SCNQuaternion(
            x: -0.659327924251556,
            y: 0.00110108347143978,
            z: -0.00492901774123311,
            w: 0.751838564872742
        )
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
        handNode.update(with: data)
    }
}

class LeapVisualizationHandNode: SCNNode {
    
    private lazy var palm: SCNNode = {
        let geometry = SCNSphere(radius: 30)
        geometry.firstMaterial?.diffuse.contents = NSColor.white.withAlphaComponent(0.2)
        let node = SCNNode(geometry: geometry)
        return node
    }()
    
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
        addChildNode(palm)
        fingers.forEach {
            addChildNode($0)
        }
    }
    
    func update(with data: LeapHandRepresentation) {
        palm.position = data.position
        print(data.fingers.count)
        guard data.fingers.count == 5 else {
            return
        }
        for i in 0...fingers.count - 1 {
            fingers[i].update(with: data.fingers[i])
        }
    }
}

class LeapVisualizationFingerNode: SCNNode {
    
    let type: LeapFingerType
    
    private lazy var mcpJoint: SCNNode = self.makeJoint()
    private lazy var pipJoint: SCNNode = self.makeJoint()
    private lazy var dipJoint: SCNNode = self.makeJoint()
    private lazy var tipJoint: SCNNode = self.makeJoint()
    
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
        joints.forEach {
            addChildNode($0)
        }
    }
    
    private func makeJoint() -> SCNNode {
        let geometry = SCNSphere(radius: 2)
        return SCNNode(geometry: geometry)
    }
    
    func update(with data: LeapFingerRepresentation) {
        mcpJoint.position = data.mcpPosition
        pipJoint.position = data.pipPosition
        dipJoint.position = data.dipPosition
        tipJoint.position = data.tipPosition
    }
}
