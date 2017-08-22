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
    func willUpdateData()
    func didStopUpdatingData()
    func didUpdate(handRepresentation: LeapHandRepresentation)
}

class LeapService: NSObject, LeapListener {
    
    var delegate: LeapServiceDelegate?

    // MARK: reflect if the service is currently updating its data
    fileprivate var isUpdatingData: Bool = false {
        willSet {
            if newValue != isUpdatingData {
                newValue == true ? delegate?.willUpdateData() : delegate?.didStopUpdatingData()
            }
        }
    }
    fileprivate var controller: LeapController?
    fileprivate var handRepresentation: LeapHandRepresentation? {
        didSet {
            guard let data = handRepresentation else {
                return
            }
            delegate?.didUpdate(handRepresentation: data)
        }
    }

    func run() {
        controller = LeapController()
        controller?.addListener(self)
    }
}

extension LeapService {
    
    func onInit(_ notification: Notification!) {
        print("LeapMotion Listener Initialized")
    }
    
    func onConnect(_ notification: Notification!) {
        print("LeapMotion Listener Connected")
        guard let controller: LeapController = notification.object as? LeapController else {
            return
        }
        controller.enable(LEAP_GESTURE_TYPE_CIRCLE, enable: true)
        controller.enable(LEAP_GESTURE_TYPE_KEY_TAP, enable: true)
        controller.enable(LEAP_GESTURE_TYPE_SCREEN_TAP, enable: true)
        controller.enable(LEAP_GESTURE_TYPE_SWIPE, enable: true)
    }
    
    func onDisconnect(_ notification: Notification!) {
        isUpdatingData = false
        print("LeapMotion Listener Disconnected")
    }
    
    func onServiceConnect(_ notification: Notification!) {
        print("LeapMotion Service Connected")
    }
    
    func onServiceDisconnect(_ notification: Notification!) {
        isUpdatingData = false
        print("LeapMotion Service Disconnected")
    }
    
    func onDeviceChange(_ notification: Notification!) {
        print("LeapMotion Device Changed")
    }
    
    func onExit(_ notification: Notification!) {
        isUpdatingData = false
        print("LeapMotion Listener Exited")
    }
    
    // MARK: gets called each time a new frame gets emitted
    func onFrame(_ notification: Notification!) {
        guard
            let controller: LeapController = notification.object as? LeapController,
            let frame = controller.frame(0),
            let hands = frame.hands,
            let firstHand = hands.first as? LeapHand,
            firstHand.isValid// && firstHand.confidence > 0.05
        else {
            isUpdatingData = false
            return
        }
        
        isUpdatingData = true
        var leapHandRepresentation = firstHand.getRepresentation()
        guard let translation = firstHand.translation(controller.frame(1)) else {
            handRepresentation = leapHandRepresentation
            return
        }
        leapHandRepresentation?.translation = SCNVector3(
            x: CGFloat(translation.x),
            y: CGFloat(translation.y),
            z: CGFloat(translation.z)
        )
        handRepresentation = leapHandRepresentation
    }
}

// MARK: structure describing a simplified representation of the interaction box from a LeapMotion device
struct LeapInteractionBoxRepresentation {
    let center: SCNVector3
    let width: CGFloat
    let height: CGFloat
    let depth: CGFloat
}

// MARK: structure describing a simplified representation of a hand
struct LeapHandRepresentation {
    var translation: SCNVector3?
    let position: SCNVector3
    let eulerAngles: SCNVector3
    let fingers: [LeapFingerRepresentation]
}

// MARK: structure describing a simplified representation of a finger
struct LeapFingerRepresentation {
    let type: LeapFingerType
    let mcpPosition: SCNVector3
    let pipPosition: SCNVector3
    let dipPosition: SCNVector3
    let tipPosition: SCNVector3
}

// MARK: enum representing the different finger types
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

// MARK: enum representing the different joins of a finger
enum LeapFingerJointType {
    case mcp
    case pip
    case dip
    case tip
}

extension LeapInteractionBox {
    
    // MARK: returns an interaction box representation
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
    
    // MARK: returns the representation of a hand
    func getRepresentation() -> LeapHandRepresentation? {
        guard let fingerData = getFingerRepresentations() else {
            return nil
        }
        let roundingPlaces = 2
        let position = SCNVector3(
            x: CGFloat(palmPosition.x).roundTo(places: roundingPlaces),
            y: CGFloat(palmPosition.y).roundTo(places: roundingPlaces),
            z: CGFloat(palmPosition.z).roundTo(places: roundingPlaces)
        )
        let eulerAngles = SCNVector3(
            x: CGFloat(direction.pitch).roundTo(places: roundingPlaces),
            y: CGFloat(-direction.yaw).roundTo(places: roundingPlaces),
            z: CGFloat(palmNormal.roll).roundTo(places: roundingPlaces)
        )
        return LeapHandRepresentation(
            translation: nil,
            position: position,
            eulerAngles: eulerAngles,
            fingers: fingerData
        )
    }
    
    // MARK: returns an array of finger representation from the hand
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
    
    // MARK: returns representation of a fingers position
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
    
    // MARK: returns the type of a finger
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
    
    // MARK: returns the position of a fingers joint
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
    // MARK: returns the finger of a specified type from an array of fingers
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
