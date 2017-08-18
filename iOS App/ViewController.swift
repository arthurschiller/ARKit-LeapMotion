//
//  ViewController.swift
//  iOS App
//
//  Created by Arthur Schiller on 28.07.17.
//

import UIKit
import SceneKit

class ViewController: UIViewController {
    
    @IBOutlet weak var connection: UILabel!
    @IBOutlet weak var valueLabel: UILabel!
    
    private let central: LeapMotionGestureCentral = LeapMotionGestureCentral()
    private let jsonDecoder = JSONDecoder()
    
    private let sceneView = SCNView()
    private let interactiveARScene = InteractiveARScene()
    
    var leapHandData: LeapHandData? = nil {
        didSet {
            guard let data = leapHandData else {
                return
            }
//            interactiveARScene.updateGeometry(with: data)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        commonInit()
    }
    
    private func commonInit() {
        valueLabel.text = ""
        central.delegate = self
        setupScene()
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
    
    private func handle(leapHandDataString: String) {
        let floatValues = leapHandDataString.components(separatedBy: ",")
            .flatMap {
                ($0 as NSString).floatValue
        }
        guard floatValues.count == 6 else {
            print("Received unexpected data.")
            return
        }
        interactiveARScene.updateGeometryPosition(with:
            SCNVector3(
                x: floatValues[0],
                y: floatValues[1],
                z: floatValues[2]
            )
        )
        interactiveARScene.updateGeometryEulerAngles(with:
            SCNVector3(
                x: floatValues[3],
                y: floatValues[4],
                z: floatValues[5]
            )
        )
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
        case .leapHandData(let extractedData):
            guard let leapHandData = try? self.jsonDecoder.decode(LeapHandData.self, from: extractedData) else {
                return
            }
            print(leapHandData)
            self.leapHandData = leapHandData
        case .lhData(let string):
            connection.text = string
            handle(leapHandDataString: string)
        }
    }
}
