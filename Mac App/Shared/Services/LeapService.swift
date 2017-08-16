//
//  LeapService.swift
//  Mac App
//
//  Created by Arthur Schiller on 12.08.17.
//

import Cocoa
import SceneKit
import CoreGraphics

protocol LeapServiceDelegate {
//    func didUpdate(palmPosition: LeapService.PalmPosition)
    func didUpdate(interactionBoxRepresentation: LeapInteractionBoxRepresentation)
    func didUpdate(handRepresentation: LeapHandRepresentation)
}

class LeapService: NSObject, LeapListener {
    
    var delegate: LeapServiceDelegate?
    
    private var controller: LeapController?
    private var interactionBoxRepresentation: LeapInteractionBoxRepresentation? {
        didSet {
            guard let data = interactionBoxRepresentation else {
                return
            }
            delegate?.didUpdate(interactionBoxRepresentation: data)
        }
    }
    private var handRepresentation: LeapHandRepresentation? {
        didSet {
            guard let data = handRepresentation else {
                return
            }
            delegate?.didUpdate(handRepresentation: data)
        }
    }
    
    override init() {
        super.init()
    }
    
    func run() {
        controller = LeapController()
        controller?.addListener(self)
    }
}

struct LeapInteractionBoxRepresentation {
    let center: SCNVector3
    let width: CGFloat
    let height: CGFloat
    let depth: CGFloat
}

struct LeapHandRepresentation {
    let position: SCNVector3
    let fingers: [LeapFingerRepresentation]
}

struct LeapFingerRepresentation {
    let type: LeapFingerType
    let mcpPosition: SCNVector3
    let pipPosition: SCNVector3
    let dipPosition: SCNVector3
    let tipPosition: SCNVector3
}

enum LeapFingerType {
    case thumb
    case index
    case middle
    case ring
    case pinky
    
    static let types = [
        LeapFingerType.thumb,
        LeapFingerType.index,
        LeapFingerType.middle,
        LeapFingerType.ring,
        LeapFingerType.pinky
    ]
}

enum LeapFingerJointType {
    case mcp
    case pip
    case dip
    case tip
}

extension LeapService {
    
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
            let frame = controller.frame(0),
            let hands = frame.hands,
            let firstHand = hands.first as? LeapHand,
            firstHand.isValid && firstHand.confidence > 0.4
        else {
            return
        }
        
        handRepresentation = firstHand.getRepresentation()
        
        /*if interactionBoxRepresentation == nil {
            guard frame.interactionBox() != controller.frame(1).interactionBox() && frame.interactionBox().isValid else {
                return
            }
            interactionBoxRepresentation = frame.interactionBox().getRepresentation()
        }*/
    }
}

extension LeapInteractionBox {
    func getRepresentation() -> LeapInteractionBoxRepresentation? {
        guard isValid else {
            return nil
        }
        return LeapInteractionBoxRepresentation(
            center: SCNVector3(
                x: CGFloat(center.x),
                y: CGFloat(center.y),
                z: CGFloat(center.z)
            ),
            width: CGFloat(width),
            height: CGFloat(height),
            depth: CGFloat(depth)
        )
    }
}

extension LeapHand {
    func getRepresentation() -> LeapHandRepresentation? {
        guard let fingerData = getFingerRepresentations() else {
            return nil
        }
        let position = SCNVector3(
            x: CGFloat(stabilizedPalmPosition.x),
            y: CGFloat(stabilizedPalmPosition.y),
            z: CGFloat(stabilizedPalmPosition.z)
        )
        return LeapHandRepresentation(
            position: position,
            fingers: fingerData
        )
    }
    
    func getFingerRepresentations() -> [LeapFingerRepresentation]? {
        guard let fingers: [LeapFinger] = fingers as? [LeapFinger] else {
            return nil
        }
        
        var fingerData: [LeapFingerRepresentation] = []
        for i in 0...LeapFingerType.types.count - 1 {
            let type: LeapFingerType = LeapFingerType.types[i]
            guard let finger = LeapHelpers.init().get(finger: type, from: fingers) else {
                return nil
            }
            fingerData.append(
                LeapFingerRepresentation(
                    type: type,
                    mcpPosition: finger.position(of: .mcp),
                    pipPosition: finger.position(of: .pip),
                    dipPosition: finger.position(of: .dip),
                    tipPosition: finger.position(of: .tip)
                )
            )
        }
        return fingerData
    }
}

extension LeapFinger {
    func getRepresentation() -> LeapFingerRepresentation? {
        guard let type = getType() else {
            return nil
        }
        return LeapFingerRepresentation(
            type: type,
            mcpPosition: position(of: .mcp),
            pipPosition: position(of: .pip),
            dipPosition: position(of: .dip),
            tipPosition: position(of: .tip)
        )
    }
    
    func getType() -> LeapFingerType? {
        switch type {
        case LEAP_FINGER_TYPE_THUMB:
            return LeapFingerType.thumb
        case LEAP_FINGER_TYPE_INDEX:
            return LeapFingerType.index
        case LEAP_FINGER_TYPE_MIDDLE:
            return LeapFingerType.middle
        case LEAP_FINGER_TYPE_RING:
            return LeapFingerType.ring
        case LEAP_FINGER_TYPE_PINKY:
            return LeapFingerType.pinky
        default:
            return nil
        }
    }
    
    func position(of joint: LeapFingerJointType) -> SCNVector3 {
        let position: LeapVector
        switch joint  {
        case .mcp:
            position = jointPosition(LeapFingerJoint.init(0))
        case .pip:
            position = jointPosition(LeapFingerJoint.init(1))
        case .dip:
            position = jointPosition(LeapFingerJoint.init(2))
        case .tip:
            position = jointPosition(LeapFingerJoint.init(3))
        }
        return SCNVector3(
            x: CGFloat(position.x),
            y: CGFloat(position.y),
            z: CGFloat(position.z)
        )
    }
}

struct LeapHelpers {
    func get(finger: LeapFingerType, from fingers: [LeapFinger]) -> LeapFinger? {
        guard fingers.count == 5 else {
            return nil
        }
        switch finger {
        case .thumb:
            return fingers[0].isValid ? fingers[0] : nil
        case .index:
            return fingers[1].isValid ? fingers[1] : nil
        case .middle:
            return fingers[2].isValid ? fingers[2] : nil
        case .ring:
            return fingers[3].isValid ? fingers[3] : nil
        case .pinky:
            return fingers[4].isValid ? fingers[4] : nil
        }
    }
}
