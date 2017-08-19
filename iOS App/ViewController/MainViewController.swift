//
//  MainViewController.swift
//  iOS App
//
//  Created by Arthur Schiller on 19.08.17.
//

import UIKit
import ARKit

class MainViewController: UIViewController {
    
    // MARK: InterfaceBuilder Outlets
    @IBOutlet weak var arSceneView: ARSCNView!
    
    // MARK: Private properties
    private lazy var sceneManager: InteractiveARSceneManager = InteractiveARSceneManager(sceneView: self.arSceneView)
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        sceneManager.runSession()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneManager.pauseSession()
    }
}

