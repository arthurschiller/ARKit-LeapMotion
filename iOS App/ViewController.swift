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
    let demoView = UIView()

    override func viewDidLoad() {
        super.viewDidLoad()
        valueLabel.text = ""
        central.delegate = self
        
        demoView.translatesAutoresizingMaskIntoConstraints = false
        demoView.backgroundColor = UIColor.green
        view.addSubview(demoView)
        
        NSLayoutConstraint.activate([
            demoView.widthAnchor.constraint(equalToConstant: 100),
            demoView.heightAnchor.constraint(equalToConstant: 100),
            demoView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            demoView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -100)
        ])
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
            
//            print(extracted)
            guard let floatValue = Float(extracted) else {
                return
            }
            print(floatValue)
            
            let translationX: CGAffineTransform = .init(translationX: CGFloat(floatValue), y: 0)
            demoView.transform = translationX
            
//            guard let translationX = NumberFormatter().number(from: extracted) else {
//                print("unable to format number")
//                return
//            }
//            print(translationX)
//            let string = "\(extracted)"
//            print(string)
//            valueLabel.text = string
        }
    }
}
