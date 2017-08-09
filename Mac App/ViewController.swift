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
        leapService?.delegate = self
        leapService?.run()
    }

    @IBAction func testStringTextFieldTextDidChange(_ sender: Any) {
        guard let textField = sender as? NSTextField else {
            return
        }
        print(textField.stringValue)
        leapMotionGesturePeripheral.set(testString: textField.stringValue)
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

extension ViewController: LeapServiceDelegate {
    func didUpdate(palmPosition: LeapService.PalmPosition) {
        let text = "PositionX: \(palmPosition.x), PositionY: \(palmPosition.y)"
        leapMotionGesturePeripheral.set(testString: text)
    }
}

protocol LeapServiceDelegate {
    func didUpdate(palmPosition: LeapService.PalmPosition)
}

class LeapService: NSObject, LeapListener {
    private var controller: LeapController?
    
    var delegate: LeapServiceDelegate?
    
    override init() {
        super.init()
    }
    
    func run() {
        controller = LeapController()
        controller?.addListener(self)
        print("running")
    }
}

extension LeapService{
    
    func onInit(_ notification: Notification!) {
        print("Initialized")
    }
    
    func onConnect(_ notification: Notification!) {
        print("Connected")
        guard let controller: LeapController = notification.object as? LeapController else {
            return
        }
        controller.enable(LEAP_GESTURE_TYPE_CIRCLE, enable: true)
        controller.enable(LEAP_GESTURE_TYPE_KEY_TAP, enable: true)
        controller.enable(LEAP_GESTURE_TYPE_SCREEN_TAP, enable: true)
        controller.enable(LEAP_GESTURE_TYPE_SWIPE, enable: true)
    }
    
    func onDisconnect(_ notification: Notification!) {
        print("Disconnected")
    }
    
    func onServiceConnect(_ notification: Notification!) {
        print("Service Connected")
    }
    
    func onServiceDisconnect(_ notification: Notification!) {
        print("Service Disconnected")
    }
    
    func onDeviceChange(_ notification: Notification!) {
        print("Device Changed")
    }
    
    func onExit(_ notification: Notification!) {
        print("Exited")
    }
    
    func onFrame(_ notification: Notification!) {
        guard
            let controller: LeapController = notification.object as? LeapController,
            let frame = controller.frame(0)
        else {
            return
        }
        
        if let hands = frame.hands {
//            print("You are showing \(hands.count) hands")
            for hand in hands {
//                print("Hand: \(hand)")
                
                guard let leapHand = hand as? LeapHand else {
                    return
                }
                
//                let rotationX = leapHand.direction.roll.radiansToDegrees
//                let rotationX = Measurement(value: Double(leapHand.direction.roll), unit: UnitAngle.radians).converted(to: UnitAngle.degrees)
                
                
                let rotationX = leapHand.direction.roll.radiansToDegrees
                let rotationY = leapHand.direction.pitch.radiansToDegrees
                let rotationZ = leapHand.direction.yaw.radiansToDegrees
                
                let previousFrame = controller.frame(1)
                
                let displayWidth: Float = 375
                let displayHeight: Float = 667
                let maxY: Float = 500
                
                let position = leapHand.palmPosition
                guard let normalizedPosition = frame.interactionBox().normalizePoint(position, clamp: true) else {
                    return
                }
                let posX = normalizedPosition.x * displayWidth
                let posY = normalizedPosition.y * displayHeight
                let posZ = normalizedPosition.z * maxY
                
                let palmPositon = PalmPosition(x: posX, y: posY, z: posZ)
                
//                print("PositionX: \(posX), PositionY: \(posY)")
                delegate?.didUpdate(palmPosition: palmPositon)
            }
        }
    }
    
    struct PalmPosition {
        let x: Float
        let y: Float
        let z: Float
    }
}
