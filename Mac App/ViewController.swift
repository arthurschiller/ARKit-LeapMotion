//
//  ViewController.swift
//  Mac App
//
//  Created by Arthur Schiller on 24.07.17.
//

import Cocoa

class ViewController: NSViewController {
    
    @IBOutlet weak var testStringTextField: NSTextField!
    let leapMotionGesturePeripheral = LeapMotionGesturePeripheral()
    var leapService: LeapService?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        testStringTextField.delegate = self
        leapMotionGesturePeripheral.startAdvertising()
        
        leapService = LeapService()
//        leapService?.delegate = self
        leapService?.run()
    }

    @IBAction func testStringTextFieldTextDidChange(_ sender: Any) {
        guard let textField = sender as? NSTextField else {
            return
        }
        print(textField.stringValue)
//        leapMotionGesturePeripheral.set(testString: textField.stringValue)
    }
    
    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
}

extension ViewController: NSTextFieldDelegate {
    override func controlTextDidChange(_ obj: Notification) {
        print("changed")
//        leapMotionGesturePeripheral.set(testString: testStringTextField.stringValue)
    }
}

extension ViewController: LeapDelegate {
    
    func onInit(_ controller: LeapController!) {
        print("Initialized")
    }
    
    func onConnect(_ controller: LeapController!) {
        print("Connected")
    }
}
/*
extension ViewController: LeapServiceDelegate {
    
    func interactionBoxDataDidChange(interactionBoxData: LeapInteractionBoxData) {
        
    }
    
    func didUpdate(palmPosition: LeapService.PalmPosition) {
//        let text = "PositionX: \(palmPosition.x), PositionY: \(palmPosition.y)"
        let text = String(palmPosition.x.roundTo(places: 2))
        leapMotionGesturePeripheral.set(testString: text)
    }
}
*/
