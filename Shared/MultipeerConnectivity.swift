//
//  MultipeerConnectivity.swift
//  ARKit LeapMotion Control
//
//  Created by Arthur Schiller on 20.08.17.
//

import Foundation
import CoreGraphics
import MultipeerConnectivity

struct LMMCService {
    static let type: String = "as-lmd"
}

struct LMHData {
    let x: Float
    let y: Float
    let z: Float
    let pitch: Float
    let yaw: Float
    let roll: Float
    
    init(
        x: Float,
        y: Float,
        z: Float,
        pitch: Float,
        yaw: Float,
        roll: Float
    ){
        self.x = x
        self.y = y
        self.z = z
        self.pitch = pitch
        self.roll = roll
        self.yaw = yaw
    }
    
    init(
        x: CGFloat,
        y: CGFloat,
        z: CGFloat,
        pitch: CGFloat,
        yaw: CGFloat,
        roll: CGFloat
    ){
        self.x = Float(x)
        self.y = Float(y)
        self.z = Float(z)
        self.roll = Float(roll)
        self.pitch = Float(pitch)
        self.yaw = Float(yaw)
    }
    
    init(fromBytes: [UInt8]) {
        self.x = fromByteArray(Array(fromBytes[0...3]), Float.self)
        self.y = fromByteArray(Array(fromBytes[4...7]), Float.self)
        self.z = fromByteArray(Array(fromBytes[8...11]), Float.self)
        self.roll = fromByteArray(Array(fromBytes[12...15]), Float.self)
        self.pitch = fromByteArray(Array(fromBytes[16...19]), Float.self)
        self.yaw = fromByteArray(Array(fromBytes[20...23]), Float.self)
    }
    
    func toBytes() -> [UInt8] {
        let composite = [x, y, z, pitch, yaw, roll]
        return composite.flatMap(){ toByteArray($0) }
    }
}


// http://stackoverflow.com/questions/26953591/how-to-convert-a-double-into-a-byte-array-in-swift
func toByteArray<T>(_ value: T) -> [UInt8] {
    var value = value
    return withUnsafeBytes(of: &value) { Array($0) }
}

func fromByteArray<T>(_ value: [UInt8], _: T.Type) -> T {
    return value.withUnsafeBytes {
        $0.baseAddress!.load(as: T.self)
    }
}
