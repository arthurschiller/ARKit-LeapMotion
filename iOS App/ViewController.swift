//
//  ViewController.swift
//  iOS App
//
//  Created by Arthur Schiller on 28.07.17.
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet weak var connection: UILabel!
    @IBOutlet weak var valueLabel: UILabel!
    
    let central: LeapMotionGestureCentral = LeapMotionGestureCentral()

    override func viewDidLoad() {
        super.viewDidLoad()
        valueLabel.text = ""
        central.delegate = self
    }
}

extension ViewController: LeapMotionGestureCentralDelegate {
    func central(_ central: LeapMotionGestureCentral, didPerformAction action: LeapMotionGestureCentral.Action) {
        switch action {
        case .read(let value):
            update(value)
        case .connectPeripheral(_):
            connection.text = "connected"
        case .disconnectPeripheral:
            connection.text = "disconnected"
        }
    }
    
    private func update(_ value: LeapMotionGestureCentral.Value) {
        switch value {
        case .testString(let extracted):
            let string = "\(extracted)"
            print(string)
            valueLabel.text = string
        }
    }
}
